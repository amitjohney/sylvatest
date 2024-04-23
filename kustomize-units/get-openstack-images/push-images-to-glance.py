#!/usr/bin/env python
#
# This script can be tested with:
#
#   OS_IMAGES_INFO_PATH=my-os-images.info.yaml TARGET_NAMESPACE=sylva-system \
#   OS_CLIENT_CONFIG_FILE=./cloud.yaml OS_CLOUD=capo_cloud
#    kustomize-units/get-openstack-images/push-images-to-glance.py
#
# With my-os-images.info.yaml having content similar as the one produced by the os-images-info unit:
#
#   kubectl get configmap os-images-info -o yaml | yq '.data."values.yaml"' > my-os-images.info.yaml
#
# And cloud.yaml with the content similar to:
#
#   kubectl get secrets cluster-cloud-config -n sylva-system -o yaml | \
#   yq '.data."clouds.yaml"' | base64 -d > clouds.yaml

from kubernetes import client, config
from kubernetes.client.rest import ApiException
import openstack
import oras.client
import oras.provider
import requests
import tempfile
from urllib.parse import urlparse
import logging
import os
import shutil
import tarfile
import gzip
import yaml
import time
import sys


logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s %(levelname)s %(name)s %(funcName)s: %(message)s')
logger = logging.getLogger(__name__)
sys.tracebacklimit = 0
# PARAMETERS retrieved from ENV vars
TIMEOUT = os.environ.get('IMAGE_IN_PROGRESS_TIMEOUT', '3600')
if TIMEOUT.isnumeric():
    TIMEOUT = int(TIMEOUT)
else:
    logger.exception("IMAGE_IN_PROGRESS_TIMEOUT must be numeric")
    sys.exit(22)
INTERVAL = os.environ.get('IMAGE_IN_PROGRESS_INTERVAL', '10')
if INTERVAL.isnumeric():
    INTERVAL = int(INTERVAL)
else:
    logger.exception("IMAGE_IN_PROGRESS_INTERVAL must be numeric")
    sys.exit(22)
WAIT_QUEUED_IMAGE = os.environ.get('WAIT_QUEUED_IMAGE', '10')
if WAIT_QUEUED_IMAGE.isnumeric():
    WAIT_QUEUED_IMAGE = int(WAIT_QUEUED_IMAGE)
else:
    logger.exception("WAIT_QUEUED_IMAGE must be numeric")
    sys.exit(22)
ORAS_PULL_MAX_ATTEMPTS = os.environ.get('ORAS_PULL_MAX_ATTEMPTS', '5')
if ORAS_PULL_MAX_ATTEMPTS.isnumeric():
    ORAS_PULL_MAX_ATTEMPTS = int(ORAS_PULL_MAX_ATTEMPTS)
else:
    logger.exception("ORAS_PULL_MAX_ATTEMPTS must be numeric")
    sys.exit(22)
NAMESPACE = os.environ.get('TARGET_NAMESPACE')
if not NAMESPACE:
    logger.exception("NAMESPACE not set")
    sys.exit(22)
os_images_info_path = os.environ.get("OS_IMAGES_INFO_PATH", '/opt/config/os-images-info.yaml')
if not os.path.exists(os_images_info_path):
    logger.exception(f"{os_images_info_path} not found")
    sys.exit(2)
# 'capo-cloud' is the cloud name we hardcode for CAPO in Sylva
cloud_name = os.environ.get("OS_CLOUD", "capo_cloud")


class k8sConnector(object):
    def __init__(self, namespace):
        try:
            config.load_incluster_config()
        except Exception as E:
            # this is meant to allow testing this script manually out of a pod,
            # assuming that KUBECONFIG points to your kubeconfig
            logger.warning(str(E))
            config.load_kube_config()
        self.api = client.CoreV1Api()
        self.namespace = namespace
        self.configmap = {}

    def create_or_update_configmap(self, data):
        metadata = client.V1ObjectMeta(
            name="openstack-images-uuids",
            namespace=self.namespace
        )
        # Convert configmap to yaml-formatted string
        # os_images is the key expected for sylva-capi-cluster chart values
        yaml_string = yaml.dump(
            {'os_images': data},
            default_flow_style=False)
        # Create a ConfigMap object
        body = client.V1ConfigMap(
            api_version="v1",
            kind="ConfigMap",
            metadata=metadata,
            data={'values.yaml': yaml_string}
        )
        try:
            # Check if the ConfigMap exists
            self.api.read_namespaced_config_map(
                name=body.metadata.name,
                namespace=self.namespace)
            # If exists, update the ConfigMap
            api_response = self.api.replace_namespaced_config_map(
                name=body.metadata.name, namespace=self.namespace, body=body)
            # api_response = self.api.replace_namespaced_config_map(
            #     name=body.metadata.name, namespace=self.namespace, body=body)
            logger.info(f"ConfigMap updated. {self.namespace}/{api_response.metadata.name}")
        except ApiException as E:
            if E.status == 404:
                # If not exists, create the ConfigMap
                try:
                    api_response = self.api.create_namespaced_config_map(namespace=self.namespace, body=body)
                    logger.info(f"ConfigMap created. {self.namespace}/{api_response.metadata.name}")
                except ApiException as E:
                    logger.warning(f"Failed to create ConfigMap after not finding an existing one: {str(E)}")
                    raise E
            else:
                # Handle other exceptions
                logger.warning(f"Exception occurred while updating or creating ConfigMap: {str(E)}")
                raise


class openstackConnector(object):

    def __init__(self, cloud):
        # Initialize openstack connection
        self.cloud = cloud
        try:
            self.conn = openstack.connect(cloud=cloud, verify=False)
        except openstack.exceptions.ConfigException:
            logger.exception(f"Openstack config {cloud_name} not found")
            sys.exit(22)
        self.openstack_user_project_id = self.conn.current_project_id

    def get_image_by_status(self, image_name, checksum, status=['active']):
        """
            retrieve all images matching the tag "sylva-md5-...." + image name
            warning: we don't check md5 checksum, in order to include all images with
            status matching status
        """
        try:
            # get all images with sylva-md5 tag
            images = self.conn.image.images(tags=[f"sylva-md5-{checksum}"])
        except Exception as E:
            logger.warning("Unexpected error occurred while checking images.")
            logger.warning(str(E))
            raise
        matching_images = [
            image for image in images
            if image.properties is not None and image.get('name') == image_name and
            image.status in status
        ]
        if matching_images:
            for img in matching_images:
                logger.info(f"Image {img.name} UUID:{img.id} status:{img.status} already exists.")
        return matching_images

    def wait_for_in_progress_image(self, image_name, checksum):
        """
            if an image is already "saving" wait for it to complete
            if an image is "queued" wait for 10sec and then clean it (stalling image upload)
        """
        t0 = 0
        image_active = None
        images = []
        while ((time.time() - t0 < TIMEOUT) and not image_active and images) or (t0 == 0):
            t0 = time.time()
            images = self.get_image_by_status(
                image_name=image_name,
                checksum=checksum,
                status=['active', 'queued', 'importing', 'uploading', 'saving']
            )
            for image in images:
                if image.status == 'active':
                    image_active = image
                if image.status == 'queued':
                    logger.warning(f"Stalling image {image.name} {image.id} waiting {WAIT_QUEUED_IMAGE} seconds")
                    time.sleep(WAIT_QUEUED_IMAGE)
                    _image = self.conn.image.get_image(image.id)
                    if _image.status == 'queued':
                        # probably a stalling image
                        try:
                            self.conn.image.delete_image(image.id)
                            logger.warning(f"Stalling image {image.name} {image.id} deleted")
                        except Exception as E:
                            logger.warning(f"Can't delete image {image.name} {image.id} : {str(E)}")
                if image.status in ['saving', 'importing', 'uploading']:
                    logger.info(f"Waiting for image {image.name} {image.id} to be active")
            if images and not image_active:
                t1 = time.time()
                time_to_sleep = INTERVAL-(t1-t0)
                time_to_sleep = time_to_sleep if time_to_sleep > 0 else 0
                time.sleep(time_to_sleep)
        return image_active

    def upload_image_to_glance(self, image_name, file, image_format, checksum):
        """
            Push binary image to glance if update_only is False
            else update metadata only
        """
        tag = f"sylva-md5-{checksum}"
        try:
            with open(file, 'rb') as image_data:
                image = self.wait_for_in_progress_image(image_name=image_name, checksum=checksum)
                try:
                    if not image:
                        logger.info(f"{image_name}: creating image with tag {tag}")
                        image = self.conn.image.create_image(
                            name=image_name,
                            data=image_data,
                            disk_format=image_format,
                            md5=checksum,
                            tags=[tag],
                            allow_duplicates=True
                        )
                except Exception as E:
                    logger.warning(str(E))
                logger.info(f"Image UUID: {image.id}")
                return image
        except Exception as E:
            logger.warning(str(E))
            raise E

    def update_image_in_glance(self, id, properties):
        """
            Update image properties in Glance
        """
        _image_data = self.conn.image.find_image(id)
        try:
            logger.info("Updating image properties...")
            image_properties = {f"sylva/{k}": v for k, v in properties.items()}
            logger.info(f"Image properties to update: {image_properties}")
            updated_image = self.conn.image.update_image(
                id, properties=image_properties)
            return updated_image
        except Exception as E:
            logger.warning(f"Can't update {_image_data.id}, {self.openstack_user_project_id} : {str(E)} ")
            return None

    def make_image_public(self, id):
        try:
            updated_image = self.conn.image.update_image(
                id, visibility='public')
            return updated_image
        except Exception:
            logger.warning(f"Can't make image {id} public")
            return None


class artifactDownloader(oras.provider.Registry):

    def __init__(self):
        # Initialize oras class
        self.tls_verify = False if os.environ.get(
            'INSECURE_CLIENT', 'false').lower() in ['true', 't'] else True
        super().__init__(tls_verify=self.tls_verify)

    def get_oci_manifest(self, artifact_url):
        try:
            container = self.get_container(artifact_url)
            manifest = self.get_manifest(container)
            return manifest
        except Exception:
            logger.warning(f"Failed to get OCI manifest from {artifact_url}")
            raise Exception(f"Failed to get OCI manifest from {artifact_url}")

    def pull_oci_image(self, artifact_uri):
        max_attempts = ORAS_PULL_MAX_ATTEMPTS
        result = None
        while max_attempts > 0 and not result:
            temp_dir = tempfile.mkdtemp()
            try:
                logger.info(f"Pulling image: {artifact_uri} to {temp_dir}")
                res = self.pull(target=artifact_uri, outdir=temp_dir)
                if len(res) > 1:
                    raise ValueError(
                        "Expected only one file, but multiple files were found.")
                else:
                    result = res[0]
            except Exception:
                logger.warning(f"Failed to pull image from {artifact_uri}")
                self.cleanup_directory(temp_dir)
            max_attempts -= 1
        if not result:
            logger.warning(
                f"Failed to pull image from {artifact_uri} after {ORAS_PULL_MAX_ATTEMPTS} attempts")
        return result

    def unzip_artifact(self, file_path):
        # Check if the file exists
        if not os.path.exists(file_path):
            logger.warning(f"The file '{file_path}' does not exist.")
            return None
        # Determine the extraction path
        extraction_path = os.path.dirname(file_path)
        # Extract the tar.gz file
        with tarfile.open(file_path, 'r:gz') as tar:
            tar.extractall(path=extraction_path)
            logger.info(f"Extracted '{file_path}' to '{extraction_path}'")
        # delete OCI artifact
        self.cleanup_file(file_path)
        # Initialize a variable to hold the path of a non-gzipped file, if found
        non_gz_file_path = None

        # Find and gunzip the .gz file or identify .raw/.qcow file
        for root, _, files in os.walk(extraction_path):
            for file in files:
                if file.endswith(".gz"):
                    gz_file = os.path.join(root, file)
                    extracted_file_path = gz_file[:-3]  # Removes the .gz extension
                    try:
                        logger.info(
                                f"Unzip '{gz_file}' ... ")
                        with (
                                gzip.open(gz_file, 'rb') as f_in,
                                open(extracted_file_path, 'wb') as f_out):
                            shutil.copyfileobj(f_in, f_out)
                            logger.info(
                                f"Gunzipped '{gz_file}' to '{extracted_file_path}'")
                    except OSError as E:
                        logger.warning(f"Disk full {str(E)}")
                        raise
                    self.cleanup_file(gz_file)  # delete .gz file
                    return extracted_file_path
                elif file.endswith(".raw") or file.endswith(".qcow2"):
                    # Store the path but do not return immediately to prioritize .gz extraction
                    # If no .gz file found but a .raw or .qcow file was found, return its path
                    non_gz_file_path = os.path.join(root, file)
                    logger.info(f"Found non-gzipped file '{non_gz_file_path}'.")
                    return non_gz_file_path

        # If no .gz, .raw, or .qcow file found, return None
        logger.info(f"no .gz, .raw, or .qcow file found: {', '.join([f[0] for f in os.walk(extraction_path)])}")
        return None

    def download_file(self, url):
        """
            Create a temporary directory, download file pointed by url
            returns:
                - temporary directory
                - filename path
        """
        temp_dir = tempfile.mkdtemp()
        filename = url.split('/')[-1]
        file_path = os.path.join(temp_dir, filename)
        # Use the verify_ssl parameter for the verify argument in requests.get
        logger.info(f"Downloading {filename} from {url} to {temp_dir}")
        try:
            with requests.get(url, stream=True, verify=self.tls_verify, timeout=INTERVAL) as r:
                r.raise_for_status()
                with open(file_path, 'wb') as f:
                    for chunk in r.iter_content(chunk_size=8192):
                        f.write(chunk)
            return temp_dir, file_path
        except Exception as E:
            logger.warning(f"{str(E)}")
            raise E

    def cleanup_file(self, file_path):
        """
            Remove a single file
        """
        # Delete a single file
        if os.path.exists(file_path) and os.path.isfile(file_path):
            os.unlink(file_path)
            logger.info(f"{file_path} has been deleted")

    def cleanup_directory(self, path):
        """
            Remove a complete directory
        """
        if os.path.exists(path) and os.path.isdir(path):
            shutil.rmtree(path)
            logger.info(f"Directory {path} has been removed.")
        else:
            raise Exception(f"{path} is not a directory")

# main code starts here


capo_cloud = openstackConnector(cloud_name)
donwloader = artifactDownloader()
k8s = k8sConnector(NAMESPACE)
configmap = {}

# read configmap content

with open(os_images_info_path, 'r') as file:
    os_images = yaml.safe_load(file.read())
os_images = os_images['os_images']
logger.info(f"os_images: {os_images}")

for os_name, os_image_info in os_images.items():
    artifact = os_image_info["uri"]
    md5_checksum = os_image_info['md5']
    image_format = os_image_info['image-format']
    parsed_url = urlparse(artifact)
    if os_image_info.get("commit-tag"):
        _os_name = f'{os_name}-sylva-diskimage-builder-{os_image_info["commit-tag"]}'
    else:
        _os_name = os_name
    logger.info(f"Working on image: {os_name} with MD5 checksum {md5_checksum}")
    existing_images = capo_cloud.get_image_by_status(image_name=_os_name, checksum=md5_checksum, status=['active'])
    if not existing_images:
        logger.info(f"image not in Glance: {os_name} / md5 {md5_checksum}")
        image_path = ''
        if parsed_url.scheme in ['http', 'https']:
            temp_dir, image_path = donwloader.download_file(artifact)
        elif parsed_url.scheme == 'oci':
            oras_pull_path = donwloader.pull_oci_image(artifact)
            temp_dir = os.path.dirname(oras_pull_path)
            logger.info(f"Unzipping artifact {oras_pull_path}...")
            image_path = donwloader.unzip_artifact(oras_pull_path)
        try:
            logger.info("Uploading image to Glance...")
            image = capo_cloud.upload_image_to_glance(
                image_name=_os_name, file=image_path, image_format=image_format,
                checksum=md5_checksum)
            image = capo_cloud.update_image_in_glance(image.id, os_image_info)
            logger.info(f"Image pushed to glance with image ID {image['id']}")
        except Exception:
            logger.warning("exception while pushing image to glance")
            raise
        finally:
            donwloader.cleanup_directory(temp_dir)
    else:
        existing_image = existing_images[0]
        image = capo_cloud.update_image_in_glance(existing_image.id, os_image_info)
        if image and hasattr(image, 'id'):
            logger.info(
                f"Image properties updated for image {image.id}")
        else:
            logger.warning(
                f"Image {existing_image.id} properties could not be updated")
            image = existing_image
    # try to change visibility to 'public'
    capo_cloud.make_image_public(image.id)
    # Update configmap with the existing image's UUID
    configmap.update(
        {os_name: {'openstack_glance_uuid': image.id}})
# Lastly update configmap openstack-images-uuids
k8s.create_or_update_configmap(configmap)
logger.info("We're done")
