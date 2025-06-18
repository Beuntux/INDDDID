# Terraform / OpenTofu


## Notions de base : 

- Fichier HCL -> extension .tf
- Langage déclaratif -> on définit l'état final souhaité de notre infrastructure
- Versionning
- Nombreux provider


### State (état)
- Terraform stock l'état de l'infra et sa configuration à l'aide de métadonnées dans le fichier terraform.tfstate
- Ce fichier est créé au moment de l'exécution de la commande terraform init.
- Le terraform.tfstate et stocké localement sur la machine depuis laquelle on exécute terraform.
- Il est possible d'utiliser un remote state lorsquel cela est nécessaire (travail en équipe)
	- consul
	- s3
	- postgres
	- ...
- Plan = description de l'infrastructure souhaitée.
- Lors de l'exécution, terraform va comparer le plan et le tfstate afin de définir les actions qu'il réalisera.

### Provider : fournisseur de ressources par API (principalement)
```hcl
provider "kubernetes" {
  version = "~> 1.10"
}
```

### Ressources : 
- Brique mise à disposition par l'API des provider
- Create Reade Update Delete

```hcl
resource "ressource_type" "ressource_nom" {
  arg = "valeur"
}
```

Exemple :
```hcl
resource "aws_instance" "example" {
  ami = "ami-123456"
  instance_type = "t2.micro"
}
```

### Data sources :
- Ressources non modifiable
- Outil de lecture uniquement
- Permet d'intégrer des éléments externes existants dans l'infrastructure déclarative sans avoir à les gérer directement.

Supposons que vous voulez utiliser une AMI (Amazon Machine Image) déjà existante sans en créer une nouvelle :
```hcl
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical (Ubuntu)
}

```

Vous pouvez ensuite utiliser les données lues ainsi :
```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
}
```

### Meta arguments

- count = itération

```hcl
resource "ressource_type" "ressource_nom" {
  count = nb
  arg = "valeur"
}
```

- For each
```hcl
variable "instances" {
	type = "map"
	default = {
		clef1 = "123"
		clef2 = "456
		clef3 = "789"
	}
}
resource "aws_instance" "server" {
	for_each = var.instances
	ami = each.value
	instance_type = "t2.micro"
	tags = {
		Name = each.key
	}
}
```





## Commandes de base :

```bash
terraform [Options]
```

Options :
```bash
apply          # Builds or changes infrastructure
destroy        # Destroy Terraform-managed infrastructure
import         # Import existing infrastructure into Terraform
init           # Initialize a Terraform working directory
plan           # Generate and show an execution plan
refresh        # Update local state file against real resources
show           # Inspect Terraform state or plan
validate       # Validates the Terraform files
```


## Provisioner 

- Utilisation de provisoner sur les ressources
	- remote-exec : exécution sur la machine distance (ssh)
	- local-exec : exécution sur la machine terraform
	- file

### Remote-exec



## Variables 

- Type de variables
	- string
	- number
	- bool
	- list
	- map
- Niveau des variables :
	- Plus le niveau est élevé, plus la priorité est grande.
	1. environnement
	2. fichier : terraform.tfvars
	3. fichier json : terraform.tfvars.json
	4. fichier : * auto.tfvars ou * .auto.tfvars.json
	5. CLI : -var ou -var-file

## Sources : 

https://developer.hashicorp.com/terraform

## Configuration de Proxmox

### Cloud Init

#### Création d'un template de base

Depuis notre nœud proxmox, télécharger une image-cloud-init (ici debian 12)

```bash
cd /var/lib/vz/template/iso
```

```bash 
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2
```

Personnalisation de l'image en ajoutant des paquets (nécessite que le paquet `libguestfs-tools` soit installé sur proxmox) :
```bash
virt-customize -a debian-12-genericcloud-amd64.qcow2 --install sudo,qemu-guest-agent
```

Création de la machine virtuelle template : 
```bash
qm create 9001 --name "debian-12-cloudinit" --memory 2048 --net0 virtio,bridge=vmbr0 --net1 virtio,bridge=vmbr1
```

Importer l'image dans la vm :
```bash
qm importdisk 9001 debian-12-genericcloud-amd64.qcow2 local-lvm
```

Ajout d'un tag:
```bash
qm set 9001 --tags "template,cloud-init"
```

Attacher le disque sur la VM :
```bash
qm set 9001 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9001-disk-0
```

Ajout d'un disque de type cloud-init :
```bash
qm set 9001 --ide2 local-lvm:cloudinit
```

Définition du disque de démarrage :
```bash
qm set 9001 --boot c --bootdisk scsi0
```

Ajout d'une interface VGA pour l'accès à la console depuis Proxmox :
```bash
qm set 9001 --serial0 socket --vga serial0
```

Activation de la communication avec l'agent qemu :
```bash
qm set 9001 --agent enabled=1
```

Transformer la VM en template :
```bash
qm template 9001
```

Notre template est prêt.

### Configuration de l'authentification pour OpenTofu

Nous allons créer un utilisateur et un rôle spécifique dans Proxmox, qui sera utilisé par OpenTofu. Cette approche garantit que OpenTofu n’aura que les permissions nécessaires pour effectuer ses tâches, sans accès excessif pouvant compromettre la sécurité du système.

Ajout de l'utilisateur :
```bash
pveum user add opentofu@pve --password <password>
```

Ajout d'un rôle :
```bash
pveum role add Opentofu -privs "Mapping.Audit Mapping.Modify Mapping.Use Permissions.Modify Pool.Allocate Pool.Audit Realm.AllocateUser Realm.Allocate SDN.Allocate SDN.Audit Sys.Audit Sys.Console Sys.Incoming Sys.Modify Sys.AccessNetwork Sys.PowerMgmt Sys.Syslog User.Modify Group.Allocate SDN.Use VM.Allocate VM.Audit VM.Backup VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Console VM.Migrate VM.Monitor VM.PowerMgmt VM.Snapshot.Rollback VM.Snapshot Datastore.Allocate Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit"
```

Assigner le rôle à notre utilisateur :
```bash
pveum aclmod / -user opentofu@pve -role Opentofu
```

Nous allons ensuite créer un token API pour la connexion entre Opentofu et Proxmox.
```bash
pveum user token add opentofu@pve opentofu -expire 0 -privsep 0 -comment "Opentofu token"
```

Pour réaliser certaines actions, le provider bpg à besoins de se connecter en ssh :

```bash
# On vérifie que l'agent est démarré
eval $(ssh-agent)
# On ajoute la clé privée
ssh-add ~/.ssh/id_ed25519

ssh-copy-id root@ip_de_la_vm
# On test la connexion
ssh root@ip_de_la_vm

```


### OpenTofu

#### Installation :

```bash
# Download the installer script:
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
# Alternatively: wget --secure-protocol=TLSv1_2 --https-only https://get.opentofu.org/install-opentofu.sh -O install-opentofu.sh

# Give it execution permissions:
chmod +x install-opentofu.sh

# Please inspect the downloaded script

# Run the installer:
./install-opentofu.sh --install-method deb

# Remove the installer:
rm -f install-opentofu.sh
```


## Sources : 

https://blog.stephane-robert.info/docs/virtualiser/type1/proxmox/terraform/
https://www.it-connect.fr/cours/terraform-pour-microsoft-azure/
https://www.reddit.com/r/Proxmox/comments/1fbcnng/why_is_there_no_official_proxmox_terraform/?tl=fr
https://forum.proxmox.com/threads/terraform-provider.29586/
https://blog.stephane-robert.info/post/opentofu-adoption/
https://pve.proxmox.com/wiki/Cloud-Init_Support
https://cloudinit.readthedocs.io/en/latest/index.html
https://github.com/bpg/terraform-provider-proxmox/blob/main/docs/index.md