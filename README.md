# PostgreSQL + Patroni Container

This docker container image bundles [PostgreSQL](https://www.postgresql.org/about/) database and [Patroni](https://github.com/zalando/patroni) (a template for PostgreSQL HA).

Built for use in the [PostgreSQL k8s charm](https://github.com/canonical/postgresql-k8s-operator).

Currently it uses [Postgres 12.4 on Ubuntu 20.04 LTS](https://hub.docker.com/r/ubuntu/postgres/) as the base image and adds Patroni v2.1.2 on top of it.

## Usage

This container image requires a configuration file for Patroni and also some environment variables. They are explained in the following subsections.

Once they are all set and the image is present in a registry accessible on your cluster or published along with the charm, the charm can execute the following command to start Patroni (which starts and manages PostgreSQL process lifecycle):

```sh
/usr/bin/python3 /usr/local/bin/patroni /var/lib/postgresql/data/patroni.yml # use the path where the charm pushed the configuration file
```

### Patroni configuration file

The k8s charm using this container image should push a Patroni [configuration file](https://patroni.readthedocs.io/en/latest/SETTINGS.html) with the following layout (replacing the `{{ pod_ip }}` variable with the pod IP address):

```yaml
bootstrap:
  dcs:
    postgresql:
      use_pg_rewind: true
  initdb:
  - auth-host: md5
  - auth-local: trust
  - encoding: UTF8
  - locale: en_US.UTF-8
  - data-checksums
  pg_hba:
  - host all all 0.0.0.0/0 md5
  - host replication replication {{ pod_ip }}/16 md5
bypass_api_service: true
log:
  dir: /var/log/postgresql
restapi:
  connect_address: '{{ pod_ip }}:8008'
  listen: 0.0.0.0:8008
pod_ip: '{{ pod_ip }}'
postgresql:
  connect_address: '{{ pod_ip }}:5432'
  custom_conf: /var/lib/postgresql/data/postgresql-k8s-operator.conf
  data_dir: /var/lib/postgresql/data/pgdata
  listen: 0.0.0.0:5432
  pgpass: /tmp/pgpass
use_endpoints: true
```

The charm can also change the values of these settings (but these ones are good defaults based on [Patroni k8s example](https://github.com/zalando/patroni/tree/master/kubernetes)) or choose different paths for the logs directory, data directory and custom `postgresql.conf` file based on how it's setting the paths in its code.

### Environment variables

Some additional [environment variables](https://patroni.readthedocs.io/en/latest/ENVIRONMENT.html) are required to properly start and run both Patroni and PostgreSQL:

- `PATRONI_KUBERNETES_LABELS`
  - Labels applied to the created pods and which are used by Patroni to find the members of a cluster and replicate the data.
- `PATRONI_KUBERNETES_NAMESPACE`
  - Namespace where the pods are created.
- `PATRONI_NAME`
  - Name of the member in the cluster (for example, the pod name, such as postgresql-k8s-0).
- `PATRONI_SCOPE`
  - Cluster name (can be the name of the juju deployment).
- `PATRONI_REPLICATION_USERNAME`
  - Username Patroni will use to manage PostgreSQL replication.
  - Default = replication
- `PATRONI_REPLICATION_PASSWORD`
  - Password for Patroni replication user.
- `PATRONI_SUPERUSER_USERNAME`
  - Username that is used to run `init db` in the PostgreSQL bootstrap process.
  - Default = postgres
- `PATRONI_SUPERUSER_PASSWORD`
  - Password for PostgreSQL superuser.

These variables can also be informed in the configuration file. They are listed separately from the configuration file in this README because it makes it easier to unit test the current PostgreSQL k8s charm.