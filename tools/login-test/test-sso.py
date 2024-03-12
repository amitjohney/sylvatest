from selenium import webdriver
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from pathlib import Path
from colorama import Fore, Style
import time
import os

user=os.getenv('USER_SSO')
password=os.getenv('PASSWORD_SSO')
rancher_url=os.getenv('rancher_url')
vault_url=os.getenv('vault_url')
flux_url=os.getenv('flux_url')
harbor_url=os.getenv('harbor_url')
neuvector_url=os.getenv('neuvector_url')
mgmt_only=os.getenv('ONLY_DEPLOY_MGMT')
workload_name=os.getenv('WORKLOAD_CLUSTER_NAME')
download_file=os.getenv('PWD')

options = FirefoxOptions()
options.set_preference("browser.download.dir", download_file)
options.set_preference("browser.download.folderList", 2)
options.set_preference("browser.download.manager.useWindow", False)
options.add_argument("-headless")

def navigate_to_endpoint(url):
  browser = webdriver.Firefox(options=options)
  browser.get(url)
  time.sleep(15)
  print(browser.current_url)
  print(browser.title)
  browser.implicitly_wait(10)
  return browser

def agree_to_eula(browser,delay,element):
  try:
    print("Agree to the End User License Agreement on first login")
    element_present = EC.presence_of_element_located((By.XPATH, element))
    WebDriverWait(browser, delay).until(element_present)
    browser.find_element(By.XPATH, element).click()
  except TimeoutException:
    print ("Not first login continue to SSO")

def redirect_sso(browser,delay):
  print("Redirect to SSO")
  try:
    element_present = EC.presence_of_element_located((By.ID,"username"))
    WebDriverWait(browser, delay).until(element_present)
  except TimeoutException:
    print ("Cannot access SSO Sign In page")
    exit (1)

def check_sso(browser,delay,element):
  try:
    element_present = EC.presence_of_element_located((By.XPATH, element))
    WebDriverWait(browser, delay).until(element_present)
  except TimeoutException:
    print ("Cannot access SSO option")
    exit (1)

def login_to_sso(browser, username, password):
  print(browser.title)
  print(browser.current_url)
  browser.implicitly_wait(10)
  browser.find_element(By.ID,"username").send_keys(username)
  browser.find_element(By.ID,"password").send_keys(password)
  browser.find_element(By.ID,"kc-login").click()
  print(browser.current_url)

def wait_for_element(service,browser,delay,locator, wait_type='presence'):
  """Wait for an element to be present or clickable based on wait_type."""
  try:
    if wait_type == 'presence':
      element_present = EC.presence_of_element_located(locator)
      WebDriverWait(browser, delay).until(element_present)
    elif wait_type == 'clickable':
      element_clickable = EC.element_to_be_clickable(locator)
      WebDriverWait(browser, delay).until(element_clickable)
    print(browser.current_url)
  except TimeoutException:
    print ("%s UI timed out" % service)
    return False
  return True

def redirect_to_ui(service,browser,delay,locator,seconds):
  print("Waiting to be redirect towards %s UI home page" % service)
  time.sleep(seconds)
  print("Redirect to %s UI home" % service)
  if not wait_for_element(service,browser, delay,(By.XPATH, '//a[@href="/dashboard/c/local/explorer"]')) or \
    not wait_for_element(service,browser, delay, (By.XPATH, '//a[@href="/dashboard/c/local/explorer"]')):
    cleanup(service,browser, success=False)

def cleanup(service,browser,success=True):
  if success:
    print(Fore.GREEN + "%s SSO check done"% (service) + Style.RESET_ALL)
  else:
    exit(1)
  browser.delete_all_cookies()
  browser.quit()

def rancher_sso(endpoint, username, password, workload_name):
  service = "Rancher"
  url='https://' + endpoint
  print("--------------------------------")
  print("Checking SSO auth Rancher")
  browser=navigate_to_endpoint(url)
  delay = 30
  element = '//button[@class="btn bg-primary"]'
  check_sso(browser,delay,element)
  browser.find_element(By.XPATH, element).click()
  redirect_sso(browser,delay)
  login_to_sso(browser,username,password)
  print("Waiting to be redirect towards rancher UI home page")
  if not wait_for_element(service,browser, delay,(By.XPATH, '//a[@href="/dashboard/c/local/explorer"]'), 'presence') and \
    not wait_for_element(service,browser, delay,(By.XPATH, '//a[@href="/dashboard/c/local/explorer"]'), 'clickable'):
    cleanup(service,browser, success=False)
  if mgmt_only == "TRUE":
      print ("No workload cluster present on this configuration")
      cleanup(service,browser)
  else:
    cluster=workload_name + '-capi'
    if not wait_for_element(service,browser, delay,(By.LINK_TEXT,cluster), 'presence') and \
    not wait_for_element(service,browser, delay,(By.LINK_TEXT,cluster), 'clickable'):
      print ("Cannot access workload cluster in Rancher UI")
      cleanup(service,browser, success=False)
    print ("Switch to workload cluster " + workload_name)
    browser.find_element(By.LINK_TEXT,cluster).click()
    time.sleep(15)
    print(browser.current_url)
    print("Getting kubeconfig for " + workload_name)
    browser.find_elements(By.XPATH, '//button[@class="btn header-btn role-tertiary has-tooltip"]')[2].click()
    rancher_config = workload_name  + '-rancher' + '.yaml'
    file = cluster + '.yaml'
    while not os.path.exists(file):
      print("Waiting until kubeconfig is successfully downloaded")
      time.sleep(5)
    os.rename( file, rancher_config)
    print("Check if the kubeconfig has been downloaded")
    path_to_file = rancher_config
    path = Path(path_to_file)
    if path.is_file():
       print(f'The kubeconfig exists')
    else:
      print(f'The kubeconfig does not exist')
    cleanup(service,browser)

def vault_sso(endpoint, username, password):
  url='https://' + endpoint
  service = 'Vault'
  print("--------------------------------")
  print("Checking SSO auth Vault")
  browser=navigate_to_endpoint(url)
  browser.find_element(By.XPATH, '//select[@id="select-ember36"]/option[text()="OIDC"]').click()
  browser.find_element(By.ID,"role").send_keys(username)
  browser.find_element(By.ID,"auth-submit").click()
  browser.find_element(By.XPATH, '//button[@id="auth-submit"]').click()
  browser.implicitly_wait(20)
  time.sleep(25)
  print(browser.current_url)
  windows=browser.window_handles
  vault=windows[0]
  sso=windows[1]
  delay = 30
  browser.switch_to.window(sso)
  redirect_sso(browser,delay)
  login_to_sso(browser,username,password)
  browser.switch_to.window(vault)
  redirect_to_ui(service,browser,delay,(By.ID,"ember70"),seconds=10)
  cleanup(browser)

def flux_sso(endpoint, username, password):
  service = "flux"
  url='https://' + endpoint
  print("--------------------------------")
  print("Checking SSO auth Flux")
  browser=navigate_to_endpoint(url)
  delay = 40
  element = '//span[@class="MuiButton-label"]'
  check_sso(browser,delay,element)
  # force to retry
  retry = 0
  while (retry < 25):
    try:
      browser.find_element(By.XPATH, element).click()
      if browser.title == "Sign in to Sylva":
        break
      retry += 1
    except:
       browser.get(url)
  redirect_sso(browser,delay)
  login_to_sso(browser,username,password)
  redirect_to_ui(service,browser,delay,(By.XPATH, '//a[@href="/applications"]'),time=25)
  cleanup(browser)

def neuvector_sso(endpoint, username, password):
  service = "Neuvector"
  url='https://' + endpoint
  if not endpoint:
    print ("Neuvector is not defined in this configuration")
  else:
    print("--------------------------------")
    browser=navigate_to_endpoint(url)
    delay = 30 # seconds
    element = '//mat-checkbox[@id="mat-checkbox-1"]'
    agree_to_eula(browser,delay,element)
    element = '//button[normalize-space()="Login with OpenID"]'
    check_sso(browser,delay,element)
    browser.find_element(By.XPATH, element).click()
    redirect_sso(browser,delay)
    login_to_sso(browser,username,password)
    delay = 25 # seconds
    redirect_to_ui(service,browser,delay,(By.XPATH, '//a[@href="#/dashboard"]'),time=50)
    cleanup(browser)

def harbor_sso(endpoint, username, password):
  service = "Harbor"
  url='https://' + endpoint
  if not endpoint:
      print ("Harbor is not defined in this configuration")
  else:
      print("--------------------------------")
      print("Checking SSO auth Harbor")
      browser=navigate_to_endpoint(url)
      delay = 30
      element = '//button[@id="log_oidc"]'
      check_sso(browser,delay,element)
      browser.find_element(By.XPATH, element).click()
      redirect_sso(browser,delay)
      login_to_sso(browser,username,password)
      redirect_to_ui(service,browser,delay,(By.XPATH, '//a[@href="/harbor/registries"]'),time=25)
      cleanup(browser)

rancher_sso( rancher_url, user, password, workload_name )
vault_sso( vault_url, user, password )
flux_sso( flux_url, user, password )
harbor_sso( harbor_url, user, password )
neuvector_sso( neuvector_url, user, password )
