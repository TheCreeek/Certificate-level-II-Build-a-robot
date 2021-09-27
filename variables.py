from RPA.Robocorp.Vault import Vault

secret = Vault().get_secret("websiteURL")
URL = secret["URL"]
