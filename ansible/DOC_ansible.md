# Ansible

## Controller Node : 

Le controller node est le serveur qui contiendra toutes les recettes. C'est depuis celui-ci qu'on déploiera les configurations sur les Managed Node.
Le controller Node doit être en capacité de se connecter en SSH sur les Managed Node.

Pour l'installation se baser sur la documentation officielle : 
https://docs.ansible.com/ansible/latest/installation_guide/index.html


Concernant la structure des dossiers, Ansible est très souple. Il faut tout de même respecter les bonnes pratiques afin de faire évoluer le projet sur le long terme.

Voici ce que Ansible propose à ce sujet : 
https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html#content-organization



Pour démarrer le déploiement, voici la commande que j'utilise : 

```bash
ansible-playbook -i inventories/hosts.ini playbook.yml --ask-become-pass
```

- `ansible-playbook` commande de base pour exécuter un playbook
- `-i` permet d'indiquer le chemin de l'inventaire des hôtes sur lesquels ont veut appliquer le déploiement (ici inventories/hosts.ini)
- `playbook.yml` nom de mon playbook
- `--as-become-pass` dans les roles, nous avons parfois besoins d'exécuter des commandes. Afin de les exécuter avec sudo, il faut ajouter l'option `become: yes`. Avec cette option, ansible me demandera de rentrer le mot de passe sudo une fois pour qu'il puisse lancer les commandes nécessitants des droits supplémentaires.

## Notions et définitions :


## Notions et définitions

### Control node :

- Nœud disposant de Ansible et permettant de déployer
- Accès ssh aux autres machines
- Password ou clé ssh
- La sécurité importante sur cette machine

### Managed nodes :

- serveurs cibles
- permet la connexion ssh
- élévation de privilèges via le user

### Inventory :

- Inventaires des machines (ip, dns)
- Format ini (plat) ou format yaml
- Fichiers de variables (host_vars et group_vars)
- Statique (fichiers) ou dynamique (api via script)
- Utilisation de patterns possible (vm-web-(0-5))

#### Groupes :

- Dans un inventaire les machines peuvent être regroupées (serveur web, databases etc.)
- Possibilité de créer différents niveaux > arbre (parents/enfants)
- Groupe racine = all

#### Groups Vars :

- Variables d'un même groupe
- Définie dans le fichier central d'inventory
- Ou dans un répertoire spécifique (reconnu par ansible)

#### Host Vars :
- Variables spécifiques à un serveur en particulier
- Surcharge d'autres variables définies plus haut dans l'arbre - ex - groupe

#### Exemple d'inventory :

/
|---inventory.yml
|---host_vars/
|---group_vars/


### Tasks :

- Actions variées (user, group, command, module)
- Format yaml

### Modules :

- Ensemble d'actions ciblées sur une utilisation commune
- Pour un outil donnée : ex. postgres, mysql, vmware etc.
- Chacune de ses actions est utilisable via une task
- Chaque action prend des options
- Les actions peuvent fournir un retour (id, résultat etc.)
- Fournis par Ansible pour l'essentiel
- Peuvent être chargés spécifiquement
- Contribution possible auprès des mainteneurs

### Rôles :

- Ensemble d'actions coordonnées pour réaliser un ensemble cohérent (installer Nginx et le configurer etc.)
- Organisé en différents outils (tasks, templates, handlers, variables (default ou non), meta)
- Peuvent être partagés sur le hub [Ansible galaxy](https://galaxy.ansible.com/ui/)
- Il vaut mieux les versionner

### Playbooks :

- Un fichier (et rien d'autres)
- Applique des rôles à un inventory
- Partie cruciale inventory > playbook > rôles
- Peut contenir des variables (à éviter)
- Peut contenir des conditions (à éviter)

### Plugins :

- Modifie ou augment les capacités de Ansible
- De différentes manières : output, inventory dynamique, strategy, test etc.


## Installation

### Prérequis :

- Controller node :
	- OS : Tout sauf windows
	- Python
	- ssh 
- Managed node :
	- Python

### Sur le controller node :

```bash
sudo apt install python3-pip
sudo apt install pipx
```

```bash
pipx install --include-deps ansible
```

### Sur le managed node :

```bash
sudo apt install python3-pip
```


## Configuration :

### Sur le controller node :

On va générer une paire de clé qui permettra au controller node de se connecter sur le managed node :
```bash
ssh-keygen -t ecdsa -b 521
```

On copie la clé publique sur le managed node :
```bash
ssh-copy-id user@x.x.x.x
```

On peut maintenant effectuer le premier test afin de savoir si notre controller node peux utiliser Ansible sur notre managed node : 

```bash
ansible -i "x.x.x.x," all -m ping
```

 
### Fichier de configuration 

Le fichier de configuration peux être directement éditer (ansible.cfg) ou peux être modifié à l'aide de commande directement depuis CLI.

Le fichier de configuration peut-être situé à différents endroits
- Dans le répertoire du playbook
- Dans home/user/.ansible/cfg
- Dans /etc/ansible/ansible.cfg


Pour générer le fichier de configuration :
```bash
ansible-config init --disabled > ansible.cfg
```

Pour voir le fichier de configuration qui s'applique : 
```bash
ansible-config view
```

Pour lister tous les paramètres Ansible configurables
```bash
ansible-config list
```



## Sources :

https://docs.ansible.com/