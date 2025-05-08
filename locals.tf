locals {
  manifest_url_format = "https://registry.ollama.ai/v2/library/%s/manifests/%s"

  model_size_mb = ceil(jsondecode(data.http.ollama_model_manifest.response_body)["layers"]["0"]["size"] / 1024 / 1024)

  ollama_image = var.gpu_brand == "nvidia" ? "ollama/ollama:latest" : "ollama/ollama:rocm"

  model_name = split(":", var.ollama_model)[0]

  model_version = length(split(":", var.ollama_model)) > 1 ? split(":", var.ollama_model)[1] : "latest"

  ec2_az = data.aws_subnet.private.availability_zone

  vpc_id = data.aws_subnet.private.vpc_id
}
