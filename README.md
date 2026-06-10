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
- `community.general` collection (`ansible-galaxy collection install community.general`)

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

### Auto-snapshots (zfs-auto-snapshot)

Installs and configures the `zfs-auto-snapshot` package. All cron scripts are set non-executable when the feature is disabled, so no orphaned schedules run.

| Variable | Default | Description |
|----------|---------|-------------|
| `zfs_auto_snapshot_enabled` | `false` | Install package and activate snapshot cron scripts |
| `zfs_auto_snapshot_package` | `zfs-auto-snapshot` | Package name |
| `zfs_auto_snapshot_hourly_keep` | `24` | Hourly snapshots to retain |
| `zfs_auto_snapshot_daily_keep` | `7` | Daily snapshots to retain |
| `zfs_auto_snapshot_weekly_keep` | `4` | Weekly snapshots to retain |
| `zfs_auto_snapshot_monthly_keep` | `3` | Monthly snapshots to retain |

```yaml
zfs_auto_snapshot_enabled: true
zfs_auto_snapshot_daily_keep: 14
zfs_auto_snapshot_weekly_keep: 8
```

### Scrub schedule

Creates (or removes) a root cron entry that runs `zpool scrub` on a named pool.

| Variable | Default | Description |
|----------|---------|-------------|
| `zfs_scrub_enabled` | `false` | Create the scrub cron job |
| `zfs_scrub_pool` | `tank` | Pool to scrub |
| `zfs_scrub_day` | `"1"` | Day-of-month for scrub (1 = 1st of each month) |
| `zfs_scrub_hour` | `"2"` | Hour the scrub runs |
| `zfs_scrub_minute` | `"0"` | Minute the scrub runs |

```yaml
zfs_scrub_enabled: true
zfs_scrub_pool: tank
zfs_scrub_day: "1"
zfs_scrub_hour: "2"
```

### SLOG (ZFS Intent Log) device

Adds a log vdev to an existing pool. The task is idempotent: it reads `zpool status` and skips the `zpool add` when a log device is already present.

| Variable | Default | Description |
|----------|---------|-------------|
| `zfs_slog_enabled` | `false` | Add a SLOG device to the pool |
| `zfs_slog_pool` | `tank` | Pool that receives the log vdev |
| `zfs_slog_device` | `""` | Full block device path, e.g. `/dev/sdb` |

```yaml
zfs_slog_enabled: true
zfs_slog_pool: tank
zfs_slog_device: /dev/sdb
```

> **Note:** Replacing an existing SLOG device requires a manual step first. The role will not add a new log device while one is already present. Run `zpool remove <pool> <old-device>` before re-running the role with the new device path.

### Dataset lifecycle management

Creates, configures, or removes datasets using the `community.general.zfs` module. Properties are applied at creation and on subsequent runs (idempotent). A warning is logged for any present-state entry that omits `mountpoint`.

| Variable | Default | Description |
|----------|---------|-------------|
| `zfs_datasets` | `[]` | List of dataset definitions (see structure below) |

Each list entry supports:

| Key | Required | Description |
|-----|----------|-------------|
| `name` | yes | Full dataset path, e.g. `tank/data` |
| `mountpoint` | no | Explicit mountpoint; omitted from properties if not set |
| `state` | no | `present` (default) or `absent` |
| `properties` | no | Dict of ZFS properties: `compression`, `atime`, `recordsize`, `sync`, `quota`, `xattr`, etc. |

```yaml
zfs_datasets:
  - name: tank/data
    mountpoint: /tank/data
    state: present
    properties:
      compression: lz4
      atime: "off"
  - name: tank/backups
    mountpoint: /tank/backups
    state: present
    properties:
      recordsize: 1M
      compression: zstd
  - name: tank/old
    state: absent
```

See [defaults/main.yml](defaults/main.yml) for the complete variable reference.

## Testing

```bash
pip install molecule molecule-docker
molecule test
```

## License

MIT

## Author

Larry Smith Jr. — [everythingshouldbevirtual.com](http://everythingshouldbevirtual.com) · [mrlesmithjr@gmail.com](mailto:mrlesmithjr@gmail.com)
