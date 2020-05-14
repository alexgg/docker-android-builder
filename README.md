Android Builder on Docker Container
===================================

##### To build the container image:

    $ docker build -t android-build .

##### Android Build:

    $ docker run -it ${SRC_DIR}:/project /bin/bash
    
    To build LineageOS sources:

    $ source build/envsetup.sh
    $ breakfast <device>
    $ croot
    $ brunch <device>
