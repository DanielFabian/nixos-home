# Single source of truth for authorized SSH pubkeys allowed to log in to
# devhost variants (both the installed system as `dany`, and the installer
# environment as `root` for post-mortem debug).
#
# Quoting convention: indented strings (''...'') throughout, so backslashes
# in Windows-style account names appear literally without escaping.
{
  keys = [
    ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKcfIVEBJCwiZ8gTpjWEBY4PZYROBRZh5kDyzP+hQa3d europe\danfab@DESKTOP-C0PQAHF''
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOteZE3XjPTRI08LKeYKrGC/2l9MpowjRZLjtt50cpOD dany@DESKTOP-C0PQAHF"
    ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKokQCdppdHAO4oDnZchbUQonMO0eI0LalNI1iycdiHv azuread\danyfabian@Dany-PC''
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF9S18nP2YJR/z+AKLi1XtPYlBjRsfUeFloM9DuWwvl2 dany@Dany-PC"
  ];
}
