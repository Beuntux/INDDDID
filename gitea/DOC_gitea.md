# Gitea

Pour reproduire cet environnement, voici le contenu d'un docker-compose.yml qui permet de créer un conteneur Gitea et un conteneur qui contient un runner pour exécuter les pipelines.

```yaml
version: "3"

networks:
  gitea:
    external: false

services:
  server:
    image: docker.gitea.com/gitea:1.23.7
    container_name: gitea
    environment:
      - USER_UID=1000
      - USER_GID=1000
    restart: always
    networks:
      - gitea
    volumes:
      - ./gitea:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "3000:3000"
      - "222:22"

  runner:
    image: docker.io/gitea/act_runner:latest
    restart: always
    environment:
      GITEA_INSTANCE_URL: "${INSTANCE_URL}"
      GITEA_RUNNER_REGISTRATION_TOKEN: "${REGISTRATION_TOKEN}"
      GITEA_RUNNER_NAME: "${RUNNER_NAME}"
      GITEA_RUNNER_LABELS: "${RUNNER_LABELS}"
    volumes:
      - ./runner/config.yaml:/config.yaml
      - ./runner/data:/data
      - /var/run/docker.sock:/var/run/docker.sock

```

Pour le runner, créer un fichier .env situé dans le même répertoire que le docker-compose.yml. Ce fichier contiendra les variables d'environnements pour faire fonctionner le runner.

```env
INSTANCE_URL=http://URL_GITEA:PORT
REGISTRATION_TOKEN=TOKEN_POUR_LE_RUNNER
RUNNER_NAME=NOM_DU_RUNNER
RUNNER_LABELS=debian12,docker,api,ubuntu-latest:docker://node:16-bullseye
```


## Runner Gitea : Dockerisé ou Exécutable ? 

Bien que Gitea recommande d'utiliser le runner avec docker, il est possible d'utiliser sa version exécutable directement sur une VM. Ainsi, le runner pourra bénéficier de tous les packages déjà présents sur la VM (node-js, docker etc.). En effet, par défaut la version conteneurisé du runner ne dispose pas de packages qui pourraient être utiles par exemple pour la phase de build de notre pipeline (ex : build et push d'une image docker). Pour palier à cela dans le cas où nous souhaiterions rester sur la versions dockerisée  du runner serait d'ajouter des labels dans le .env de notre runner comme `ubuntu-latest:docker://node:16-bullseye` pour utiliser une image du runner qui intègre node-js.

Les seuls moyens de build et push l'image docker de notre projet avec un runner gitea est de faire du "DOoD" (Docker Outside of Docker) ou du "DinD" (Docker In Docker).
Pour résumer : 
- DOod -> installer la CLI Docker dans l'image de notre runner et monter le socket Docker de l'hôte.
- DinD -> installation complète de Docker dans notre conteneurs (Daemon + client)

Voici une comparaison de ces deux solutions par ChatGPT: 

### 🔎 Comparaison synthétique

| Critère                         | DOoD (Docker Outside of Docker)                | DinD (Docker In Docker)                  |
| ------------------------------- | ---------------------------------------------- | ---------------------------------------- |
| **Stabilité**                   | ✅ Très stable                                  | ❌ Moins stable (Docker dans Docker)      |
| **Performance**                 | ✅ Native (utilise Docker hôte)                 | ❌ Moins bonne (overhead important)       |
| **Sécurité**                    | ⚠️ Risque (le conteneur peut contrôler l’hôte) | ❌ Encore pire : nécessite `--privileged` |
| **Simplicité de mise en place** | ✅ Facile avec `-v /var/run/docker.sock`        | ❌ Complexe à isoler et monitorer         |
| **Utilisation recommandée**     | ✅ Runners GitHub/GitLab auto-hébergés          | ❌ CI isolée sans accès au Docker hôte    |

## Utiliser le Runner exécutable : 

Télécharger le binaire depuis le dépôt officiel : https://gitea.com/gitea/act_runner
```bash
wget https://gitea.com/gitea/act_runner/releases/download/v0.2.11/act_runner-0.2.11-linux-amd64
mv act_runner-0.2.11-linux-amd64 /usr/bin/
```

Rendre le binaire exécutable
```bash
sudo chmod +x act_runner-0.2.11-linux-amd64
```

Vérifier que le binaire fonctionne 
```bash
./act_runner-0.2.11-linux-amd64 --version
```
Ce qui devrait retourner quelque chose du genre :
```bash
act_runner version v0.2.11
```

Ensuite, il faut obtenir un token d'enregistrement (registration token).
Cela peut se faire depuis l'interface web de gitea. Il est possible d'enregistrer le runner selon différents niveau : 
- Une  instance de gitea
- Une organisation gitea
- Un dépôt gitea
Ainsi c'est le niveau auquel le token est créé qui déterminera le niveau d'application du runner.

Dans mon cas, mon runner devra exécuter mon pipeline API et mon pipeline Frontend qui sont tout deux dans la même organisation. C'est pourquoi je vais générer le token au niveau de mon organisation.


Notons qu'il est possible de générer ce token depuis la CLI :

Instance :
```bash
gitea actions generate-runner-token
```

Organisation :
```bash
gitea actions generate-runner-token -s nom_organisation
```

Dépôt :
```bash
gitea actions generate-runner-token -s username/nom-dépôt
```



Nous allons ensuite générer le fichier de configuration : 
```bash
./act_runner-0.2.11-linux-amd64 generate-config > /etc/act_runner/config.yaml
```

Ensuite nous pouvons enregistrer notre runner :
```bash
./act_runner register
```
Plusieurs questions vous serons posées : 
- L'URL de l'instance Gitea
- Le token d'enregistrement
- Le nom du runner (optionnel)
- Les labels du runner (optionnels)

Il est également possible d'enregistrer le runner de manière non-interactive avec des arguments :  
```bash
./act_runner register --no-interactive --instance <instance_url> --token <registration_token> --name <runner_name> --labels <runner_labels>
```

Après après avoir enregistrer le runner, vous trouver un fichier `.runner` dans le répertoire courant. Ce fichier stocke les informations d'enregistrement. Ce fichier doit rester dans le même répertoire que l'exécutable du runner.

Un fois le runner enregistré,  nous allons créer un utiliser `act_runner` sur le système.
```bash
sudo useradd --system --shell /usr/sbin/nologin --create-home --home-dir /var/lib/act_runner act_runner
```

Nous pouvons maintenant créer un service systemd pour exécuter le runner en tant que service :
```bash
nano /etc/systemd/system/act_runner.service
```

```bash
[Unit]
Description=Gitea Actions runner
Documentation=https://gitea.com/gitea/act_runner
After=docker.service

[Service]
ExecStart=/usr/local/bin/act_runner-0.2.11-linux-amd64 daemon --config /etc/act_runner/config.yaml
ExecReload=/bin/kill -s HUP $MAINPID
WorkingDirectory=/var/lib/act_runner
TimeoutSec=0
RestartSec=10
Restart=always
User=act_runner

[Install]
WantedBy=multi-user.target
```

**Attention :**
Pour que le service tel qu'il est ci-dessus fonctionne avec notre utilisateur `act_runner`, il faut que :

- Notre exécutable act_runner soit situé dans /usr/local/bin/ avec comme propriétaire notre utilisateur `act_runner`
- Le fichier `.runner` dans /var/lib/act_runner avec comme propriétaire notre utilisateur `act_runner`


Puisque notre runner sera amené à utiliser docker (ex: pour pull notre image sur le docker registry de Gitea) nous allons ajouter notre utilisateur `act_runner` au groupe `docker` (Attention, comporte des risques, [[https://docs.docker.com/engine/security/#docker-daemon-attack-surface|pour en savoir plus]])
```bash
usermod -aG docker act_runner
```

Ensuite, nous pouvons charger le nouveau service systemd, le démarrer et l'activer au démarrage du système :
```bash
# load the new systemd unit file
sudo systemctl daemon-reload
# start the service and enable it at boot
sudo systemctl enable act_runner --now
```




## Sources : 

https://docs.gitea.com/usage/actions/act-runner
