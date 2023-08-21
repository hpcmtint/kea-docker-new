# Docker files for building Kea containers

This is a repository that one day hopes to rise to the rank of being an official
ISC Kea Docker repository. There is a long way ahead before this could happen.
Use with caution!

Those Docker files and images are based on Alpine 3.15.

You probably want to mount the following volumes:



Strictly speaking, you don't need to mount any of them. If you don't, Kea will
run on the defaults provided, but those will almost never work for you. At the
very least, you should mount `/etc/kea` with your own config file that
corresponds to your actual network.

# Building image

You need to have Docker installed. The image can be built using the following
command (build argument VERSION is mandatory):

```shell
docker build --build-arg VERSION=2.3.8-r20230530063557 - < docker/kea-dhcp4.Dockerfile
```

If user have access to premium packages it should be added dufing build process:

```shell
docker build --build-arg VERSION=2.3.8-r20230530063557 --build-arg TOKEN=<TOKEN> - < docker/kea-dhcp4.Dockerfile
```

If provided token grants access to subcribers or enterprise packages it should be specified:

```shell
docker build --build-arg VERSION=2.3.8-r20230530063557 --build-arg TOKEN=<TOKEN> --build-arg PREMIUM=ENTERPRISE - < docker/kea-dhcp4.Dockerfile
```


This will end up with something like the following:

```shell
Successfully built <image-id>
```

# Running the image

At the very least, you should tweak the following:

- add a configuration (subnets and options, probably also shared networks,
  classes and much more) to `/etc/kea/kea-dhcp4.conf`.
- configure TLS
- possibly configure leases, host, and/or config backends to point to specific databases
- IP address on which Control Agent will listen to the traffic

Using supervisor it's possible to start dhcp and control agent in the same container:

```shell
sudo docker run --volume=<path to kea-docker repo>/config/kea/kea-dhcp4.conf:/etc/kea/kea-dhcp4.conf  \
                --volume=<path to kea-docker repo>/config/kea/kea-ctrl-agent-4.conf:/etc/kea/kea-ctrl-agent.conf  \
                --volume=<path to kea-docker repo>/config/supervisor/supervisord.conf:/etc/supervisor/supervisord.conf \
                --volume=<path to kea-docker repo>/config/supervisor/kea-dhcp4.conf:/etc/supervisor/conf.d/kea-dhcp4.conf \
                --volume=<path to kea-docker repo>/config/supervisor/kea-agent.conf:/etc/supervisor/conf.d/kea-agent.conf \
                --network=host  <image-id>
```

## Support

For information about ISC, Stork, Kea and for purchasing professional technical support from ISC, see our website.
Development and maintenance of Kea and Stork is funded by your support contracts. The kea-users mailing list
(https://lists.isc.org/mailman/listinfo/kea-users) is a resource for free community support. Please subscribe in
order to post. We would love feedback about how this Docker image is working for you!

## Documentation

Documentation for Kea is available on [ReadTheDocs](https://kea.readthedocs.io).
Further documentation, including many short FAQs is available in [ISC's Knowledgebase](kb.isc.org/).

## Issues

To report a bug, navigate to our project repository. Please try searching for your issue first in case someone else
has already logged it.

## License

Kea and Stork are licensed under the MPL2.0 license.
