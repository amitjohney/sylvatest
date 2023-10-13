from selenium import webdriver
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from pathlib import Path
import time
import os


user=os.getenv('USER_SSO')
password=os.getenv('PASSWORD_SSO')
rancher_url=os.getenv('HURL_rancher_url')
vault_url=os.getenv(' HURL_vault_url')
flux_url=os.getenv('HURL_flux_ur')
workload_name=os.getenv('workload_name')
download_file=os.getenv('PWD')

options = FirefoxOptions()
options.set_preference("browser.download.dir", download_file)
options.set_preference("browser.download.folderList", 2)
options.set_preference("browser.download.manager.useWindow", False)
options.add_argument("-headless")

def rancher_sso(endpoint, username, password, workload_name):
  print("--------------------------------")
  browser = webdriver.Firefox(options=options)
  url='https://' + endpoint
  browser.get(url)
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
  print("Waiting to be redirect toward rancher UI home page")
  time.sleep(25)
  print("Redirected to rancher UI home page")
  print(browser.current_url)
  print ("Switch to workload cluster " + workload_name)
  browser.find_element(By.LINK_TEXT,workload_name).click()
  time.sleep(15)
  print(browser.current_url)
  print("Getting kubeconfig for " + workload_name)
  browser.find_elements(By.XPATH, '//button[@class="btn header-btn role-tertiary has-tooltip"]')[2].click()
  print("Check if the kubeconfig has been downloaded")
  file=workload_name +'.yaml'
  path_to_file = file
  path = Path(path_to_file)
  if path.is_file():
      print(f'The kubeconfig exists')
  else:
    print(f'The kubeconfig does not exist')
  print ("Rancher SSO check done")
  browser.delete_all_cookies()
  browser.quit()

def vault_sso(endpoint, username):
  print("--------------------------------")
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
  print("Redirect to vault UI home")
  time.sleep(10)
  browser.switch_to.window(vault)
  print(browser.current_url)
  print("Vault SSO check done")
  browser.delete_all_cookies()
  browser.quit()

def flux_sso(endpoint, username, password):
  print("--------------------------------")
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
  print("Waiting to be redirect toward flux UI home page")
  time.sleep(25)
  print("Redirected to flux UI home page")
  print(browser.current_url)
  print ("Flux SSO check done")
  browser.delete_all_cookies()
  browser.quit()

#rancher_sso( rancher_url, user, password, workload_name )
vault_sso( vault_url, user, password )
flux_sso( flux_url, user, password )

