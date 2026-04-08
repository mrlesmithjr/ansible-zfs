# ansible-zfs

An [Ansible](https://www.ansible.com) role to install and configure [ZFS on Linux](https://openzfs.github.io/openzfs-docs/).

Supports pools, filesystems, volumes, NFS/iSCSI/Samba sharing, encryption, performance tuning, and automated scrub scheduling.

## Ansible Galaxy

```bash
ansible-galaxy install mrlesmithjr.zfs
```

## Supported Platforms

| Platform | Versions |
|----------|----------|
| Ubuntu | 20.04, 22.04, 24.04 |
| Debian | 11, 12 |
| Rocky Linux / RHEL | 8, 9 |

## Requirements

- At least one available (unformatted) disk device for pool creation
- Root / `become: true`

## Quick Start

```yaml
---
- hosts: all
  become: true
  vars:
    zfs_install_update: true
    zfs_create_pools: true
    zfs_pools:
      - name: tank
        action: create
        type: mirror
        compression: lz4
        devices:
          - /dev/sdb
          - /dev/sdc
        state: present
    zfs_create_filesystems: true
    zfs_filesystems:
      - name: data
        pool: tank
        compression: lz4
        mountpoint: /data
        state: present
  roles:
    - role: mrlesmithjr.zfs
```

## Key Variables

### Switches

| Variable | Default | Description |
|----------|---------|-------------|
| `zfs_install_update` | `true` | Install/update ZFS packages |
| `zfs_create_pools` | `false` | Create/manage zpools |
| `zfs_create_filesystems` | `false` | Create/manage ZFS filesystems |
| `zfs_create_volumes` | `false` | Create/manage ZFS block volumes |
| `zfs_enable_nfs` | `false` | Install and configure NFS kernel server |
| `zfs_enable_iscsi` | `false` | Install and configure iSCSI target |
| `zfs_enable_samba` | `false` | Install and configure Samba |
| `zfs_enable_performance_tuning` | `false` | Apply kernel parameter tuning |
| `zfs_enable_monitoring` | `false` | Enable capacity and scrub age monitoring |

### Pool Types

Supported `type` values: `basic` (no redundancy), `mirror`, `raidz`, `raidz2`, `raidz3`

### Filesystem Options

```yaml
zfs_filesystems:
  - name: data
    pool: tank
    compression: lz4        # lz4 | gzip | off
    atime: off
    quota: 100G
    mountpoint: /data
    sharenfs: on            # Enable NFS share
    state: present          # present | absent
```

### Encryption

```yaml
zfs_filesystems:
  - name: secure
    pool: tank
    state: present
    encryption: aes-256-gcm
    keylocation: "file:///etc/zfs/keys/tank/secure"
    keyformat: hex
```

### Performance Tuning

When `zfs_enable_performance_tuning: true`, the role sets kernel parameters including ARC size limits based on available system memory. See [defaults/main.yml](defaults/main.yml) for tuning parameters.

### Monitoring

```yaml
zfs_enable_monitoring: true
zfs_monitoring_capacity_threshold: 80   # Alert at 80% full
zfs_monitoring_scrub_max_age: 8         # Alert if scrub > 8 days old
zfs_monitoring_email_dest: alerts@example.com
```

See [defaults/main.yml](defaults/main.yml) for the complete variable reference.

## Testing

```bash
pip install molecule molecule-docker
molecule test
```

## Support This Project

If your organization uses this role in production, consider
[sponsoring its maintenance](https://github.com/sponsors/mrlesmithjr).
Enterprise support tiers are available.

## License

MIT

## Author

Larry Smith Jr. — [everythingshouldbevirtual.com](http://everythingshouldbevirtual.com) · [mrlesmithjr@gmail.com](mailto:mrlesmithjr@gmail.com)
