from huggingface_hub import snapshot_download
snapshot_download(repo_id="liuhaotian/llava-v1.5-7b", local_dir="./llava_weights", local_dir_use_symlinks=False)
