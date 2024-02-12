import torch

from llava.constants import IMAGE_TOKEN_INDEX, DEFAULT_IMAGE_TOKEN, DEFAULT_IM_START_TOKEN, DEFAULT_IM_END_TOKEN
from llava.conversation import conv_templates, SeparatorStyle
from llava.model.builder import load_pretrained_model
from llava.utils import disable_torch_init
from llava.mm_utils import process_images, tokenizer_image_token, get_model_name_from_path

from transformers import TextStreamer


class LLaVaInference():
    def __init__(self, model_path, device, temperature=0., max_new_tokens=512, load_8bit=False, load_4bit=False):
        self.temperature = temperature
        self.max_new_tokens = max_new_tokens

        disable_torch_init()
        model_name = get_model_name_from_path(model_path)
        self.tokenizer, self.model, self.image_processor, self.context_len = load_pretrained_model(
            model_path,
            None,
            model_name,
            load_8bit,
            load_4bit,
            device=device,
        )
        if "llama-2" in model_name.lower():
            conv_mode = "llava_llama_2"
        elif "mistral" in model_name.lower():
            conv_mode = "mistral_instruct"
        elif "v1.6-34b" in model_name.lower():
            conv_mode = "chatml_direct"
        elif "v1" in model_name.lower():
            conv_mode = "llava_v1"
        elif "mpt" in model_name.lower():
            conv_mode = "mpt"
        else:
            conv_mode = "llava_v0"
        self.conv_mode = conv_mode
        self.reset()

    def generate(self, message, image=None, debug=False):
        if image is not None:
            image_size = image.size
            image_tensor = process_images([image], self.image_processor, self.model.config)
            if type(image_tensor) is list:
                image_tensor = [image.to(self.model.device, dtype=torch.float16) for image in image_tensor]
            else:
                image_tensor = image_tensor.to(self.model.device, dtype=torch.float16)

            # first message
            if self.model.config.mm_use_im_start_end:
                message = DEFAULT_IM_START_TOKEN + DEFAULT_IMAGE_TOKEN + DEFAULT_IM_END_TOKEN + '\n' + message
            else:
                message = DEFAULT_IMAGE_TOKEN + '\n' + message

            if self.image_tensor is None:
                self.image_tensor = image_tensor
                self.image_size = image_size
            self.conv.append_message(self.conv.roles[0], message)
        else:
            # later messages
            self.conv.append_message(self.conv.roles[0], message)
        self.conv.append_message(self.conv.roles[1], None)
        prompt = self.conv.get_prompt()

        input_ids = tokenizer_image_token(prompt, self.tokenizer, IMAGE_TOKEN_INDEX, return_tensors='pt').unsqueeze(0).to(self.model.device)
        streamer = TextStreamer(self.tokenizer, skip_prompt=True, skip_special_tokens=True)

        with torch.inference_mode():
            output_ids, clip_image_features = self.model.generate(
                input_ids,
                images=image_tensor,
                image_sizes=[image_size],
                do_sample=True if self.temperature > 0 else False,
                temperature=self.temperature,
                max_new_tokens=self.max_new_tokens,
                streamer=streamer,
                use_cache=True)

        outputs = self.tokenizer.decode(output_ids[0]).strip()
        self.conv.messages[-1][-1] = outputs

        if debug:
            print("\n", {"prompt": prompt, "outputs": outputs}, "\n")
        return outputs, clip_image_features
    
    def encode_image_without_proj(self, image, feature_select="cls"):
        image_tensor = process_images([image], self.image_processor, self.model.config)
        image_feature = self.model.get_vision_tower()(image_tensor)
        if feature_select == "cls":
            image_feature = image_feature[:, 0:1]
        else:
            image_feature = image_feature[:, 1:]
        return image_feature
    
    def reset(self):
        self.conv = conv_templates[self.conv_mode].copy()
        self.image_tensor = None

if __name__ == "__main__":
    device = torch.device("cuda:0")
    model_path = "liuhaotian/llava-v1.5-7b"
    model = LLaVaInference(model_path, device)
    import requests
    from io import BytesIO
    from PIL import Image
    image_file = "https://llava-vl.github.io/static/images/view.jpg"
    if image_file.startswith('http://') or image_file.startswith('https://'):
        response = requests.get(image_file)
        image = Image.open(BytesIO(response.content)).convert('RGB')
    else:
        image = Image.open(image_file).convert('RGB')
    print(model.generate("Please describe this image.", image=image, debug=True))
