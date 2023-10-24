from selenium import webdriver
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from pathlib import Path
from colorama import Fore, Style
import time
import os

user=os.getenv('USER_SSO')
password=os.getenv('PASSWORD_SSO')
rancher_url=os.getenv('rancher_url')
vault_url=os.getenv('vault_url')
flux_url=os.getenv('flux_url')
workload_name=os.getenv('TEST_WORKLOAD_CLUSTER_NAME')
download_file=os.getenv('PWD')

options = FirefoxOptions()
options.set_preference("browser.download.dir", download_file)
options.set_preference("browser.download.folderList", 2)
options.set_preference("browser.download.manager.useWindow", False)
options.add_argument("-headless")

def rancher_sso(endpoint, username, password, workload_name):
  print("--------------------------------")
  print("Checking SSO auth Rancher")
  browser = webdriver.Firefox(options=options)
  url='https://' + endpoint
  browser.get(url)
  time.sleep(15)
  print(browser.current_url)
  print(browser.title)
  browser.implicitly_wait(10)
  browser.find_element(By.XPATH, '//button[@class="btn bg-primary"]').click()
  print("Redirect to SSO")
  print(browser.title)
  print(browser.current_url)
  browser.implicitly_wait(10)
  browser.find_element(By.ID,"username").send_keys(username)
  browser.find_element(By.ID,"password").send_keys(password)
  browser.find_element(By.ID,"kc-login").click()
  print(browser.current_url)
  print("Waiting to be redirect towards rancher UI home page")
  time.sleep(25)
  print("Redirect to rancher UI home page")
  print(browser.current_url)
  cluster=workload_name + '-capi'
  print ("Switch to workload cluster " + workload_name)
  browser.find_element(By.LINK_TEXT,cluster).click()
  time.sleep(15)
  print(browser.current_url)
  print("Getting kubeconfig for " + workload_name)
  browser.find_elements(By.XPATH, '//button[@class="btn header-btn role-tertiary has-tooltip"]')[2].click()
  rancher_config = workload_name  + '-rancher' + '.yaml'
  file = cluster + '.yaml'
  os.rename( file, rancher_config)
  print("Check if the kubeconfig has been downloaded")
  path_to_file = rancher_config
  path = Path(path_to_file)
  if path.is_file():
      print(f'The kubeconfig exists')
  else:
    print(f'The kubeconfig does not exist')
  print(Fore.GREEN + "Rancher SSO check done")
  print(Style.RESET_ALL)
  browser.delete_all_cookies()
  browser.quit()

def vault_sso(endpoint, username, password):
  print("--------------------------------")
  print("Checking SSO auth Vault")
  browser = webdriver.Firefox(options=options)
  url='https://' + endpoint
  browser.get(url)
  print(browser.current_url)
  print(browser.title)
  browser.implicitly_wait(10)
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
  print("Redirect to SSO")
  browser.switch_to.window(sso)
  print(browser.title)
  print(browser.current_url)
  browser.find_element(By.ID,"username").send_keys(username)
  browser.find_element(By.ID,"password").send_keys(password)
  browser.find_element(By.ID,"kc-login").click()
  print("Waiting to be redirect towards vault UI home page")
  time.sleep(10)
  print("Redirect to vault UI home")
  browser.switch_to.window(vault)
  print(browser.current_url)
  print(Fore.GREEN + "Vault SSO check done")
  print(Style.RESET_ALL)
  browser.delete_all_cookies()
  browser.quit()

def flux_sso(endpoint, username, password):
  print("--------------------------------")
  print("Checking SSO auth Flux")
  browser = webdriver.Firefox(options=options)
  url='https://' + endpoint
  browser.get(url)
  print(browser.current_url)
  print(browser.title)
  browser.implicitly_wait(10)
  browser.find_element(By.XPATH, '//span[@class="MuiButton-label"]').click()
  print("Redirect to SSO")
  print(browser.title)
  print(browser.current_url)
  browser.find_element(By.ID,"username").send_keys(username)
  browser.find_element(By.ID,"password").send_keys(password)
  browser.find_element(By.ID,"kc-login").click()
  print(browser.current_url)
  print("Waiting to be redirect towards flux UI home page")
  time.sleep(25)
  print("Redirect to flux UI home page")
  print(browser.current_url)
  print(Fore.GREEN + "Flux SSO check done")
  print(Style.RESET_ALL)
  browser.delete_all_cookies()
  browser.quit()

rancher_sso( rancher_url, user, password, workload_name )
vault_sso( vault_url, user, password )
flux_sso( flux_url, user, password )

