module "parent" {
  source = "./example_module"
}

output "module_output" {
  value = module.parent.sample
}