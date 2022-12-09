# Terraform CLI Extended

## Description
This project is meant to enhance the Terraform CLI by providing the ability use dynamic git refs for module sources


A normal use case is when referencing terraform modules from an external repository where you want to take advantage from branching e.g. use different implementations for different environments (dev & prod)

Normally you would have to do something like this, as Terraform does not supprt dynamic values in the source parameter.
```json
module "example" {
    source = "git::https://example.com/vpc.git?ref=master"
}
```

With Terraform CLI Extendedd you can implement it using a placeholder for the git ref
```json
module "example" {
    source = "git::https://example.com/vpc.git?ref=<place_holder>"
}
```

The call ``terraform-ext.sh -m plan -p "<place_holder>" -r dev`` will temporarily replace the placeholder, execute the terraform command reset the ref to the placeholder
```json
module "example" {
    source = "git::https://example.com/vpc.git?ref=dev"
}
```

> HINT: You can use any valid git ref like branches, tags or commits for -r values

## Available Flags
| Flag | Description                                                                                                                                                                              |
|------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| -h   | Displays the help window                                                                                                                                                                 |
| -m   | Specify the terraform command. <br />Choose from init, validate, plan, apply, destroy                                                                                                          |
| -r   | Use with Git ref replacement <br /> Specify a Git ref which should be used to download modules from external repositories in code you have to use an unique placeholder like ?ref=<placeholder> |
| -p   | Use with Git ref replacement <br />The script searches for occurrences of ?ref=<your_placeholder> and replaces it with your -r value <br />**Do not use \ {backslash} in your placeholder**                          |
| -w   | Terraform workspace name if required                                                                                                                                                     |
| -b   | Terraform backend config file                                                                                                                                                            |
| -v   | Terraform variables file                                                                                                                                                                 |
| -c   | Flag for removing the .terraform/modules folder and re-pulling modules                                                                                                                   |
| -o   | Use terraform plan files.  Plan will output a terraform.plan file in the local directory Apply will requires a terraform.plan file in the local directory                                |

## Command examples
***

| Command                                                     | Description                                                                                                         |
|-------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| ``terraform-ext.sh -m plan -o  ``                               | Performs normal Terraform plan and outputting the plan to the local directory as terraform.plan                     |
| ``terraform-ext.sh -m plan -o -p fancy_placeholder -r master``  | Performs a Terraform plan but all GIT refs matching the placeholder a replaced and referencing to the master branch |
| ``terraform-ext.sh -m apply -o``                                | Apply a local terraform.plan file                                                                                   |
| ``terraform-ext.sh -m apply -o -p fancy_placeholder -r master`` | Applies a local terraform.plan file but GIT refs matching the placeholder are replaced to the master branch         |
