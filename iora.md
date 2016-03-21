# On master server

* Cleanup bad builds
  - same sha built as part of 2 different "projects" - ie alexs_macbook & pull_request

    Build.find(1714, 5352, 6805, 6832, 6956, 8303, 7868, 8506, 7529, 7611, 8343, 7346, 8022, 7979, 7265, 8371, 8541, 7893, 7645, 8207, 7988).each &:destroy

* Password secret config in shared
    mkdir /home/ops/kochiku-master/shared/config
    cp /home/ops/kochiku-master/current/config/database.yml /home/ops/kochiku-master/shared/config

* Might need to do these in kochiku-ops - need to test a new clean upgrade

    sudo yum downgrade libyaml-0.1.3-4.el6_6
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3

(see https://github.com/rvm/rvm/issues/3347 for an explanation of the yum downgrade step)

# INSTALL

On devops laptop

```
cd kochiku
cap iora deploy
```

```
cd kochiku-worker
cap iora deploy
```


