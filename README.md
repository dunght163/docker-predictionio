docker-predictionio
===================

Run [PredictionIO](http://prediction.io) inside Docker

1. Run ```build``` to build the image
2. Run ```shell``` to start the container
3. Once inside the container, run ```runsvdir-start&``` to start everything
4. The Dashboard is available on port 9000

_Notes:_ if got error when install java, please following [this link](https://stackoverflow.com/questions/48301257/how-to-install-oracle-java8-installer-on-docker-debianjessie) and [this link](https://stackoverflow.com/questions/46815897/jdk-8-is-not-installed-error-404-not-found) to fix. E.g: 

instead of:

```
apt-get -y install oracle-java8-installer
```

use this:

```
RUN apt-get install -y oracle-java8-installer || true
RUN sed -i "s|JAVA_VERSION=8u181|JAVA_VERSION=8u191|" /var/lib/dpkg/info/oracle-java8-installer.*
RUN sed -i "s|PARTNER_URL=http://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/|PARTNER_URL=http://download.oracle.com/otn-pub/java/jdk/8u191-b12/2787e4a523244c269598db4e85c51e0c/|" /var/lib/dpkg/info/oracle-java8-installer.*
RUN sed -i 's|SHA256SUM_TGZ="1845567095bfbfebd42ed0d09397939796d05456290fb20a83c476ba09f991d3"|SHA256SUM_TGZ="53c29507e2405a7ffdbba627e6d64856089b094867479edc5ede4105c1da0d65"|' /var/lib/dpkg/info/oracle-java8-installer.*
RUN sed -i "s|J_DIR=jdk1.8.0_181|J_DIR=jdk1.8.0_191|" /var/lib/dpkg/info/oracle-java8-installer.*
RUN apt-get install -f -y && \
    apt-get install -y oracle-java8-set-default
```

Run [quickstart](http://predictionio.incubator.apache.org/templates/recommendation/quickstart/)

1. Go to quickstartapp directory ```cd /quickstartapp```
2. Build and Train Engine ```./run.sh```
3. Deploy Engine ```cd MyRecommendation && pio deploy --ip 0.0.0.0&```
4. Your Engine will now listen on port 8000


