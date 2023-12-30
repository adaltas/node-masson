
# APT

apt provides a high-level commandline interface for the package management system. It is
intended as an end user interface and enables some options better suited for interactive
usage by default compared to more specialized APT tools like 
[apt-get(8)](http://manpages.ubuntu.com/manpages/xenial/man8/apt-get.8.html) and 
[apt-cache(8)](http://manpages.ubuntu.com/manpages/xenial/man8/apt-cache.8.html).

    export default
      configure:
        'masson/core/apt/configure'
      commands:
        'install':
          'masson/core/apt/install'
