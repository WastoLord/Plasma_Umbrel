## Template de App Store Comunitária do Umbrel

Este repositório é um template para criar uma App Store Comunitária do Umbrel. Essas app stores adicionais permitem que desenvolvedores distribuam aplicações sem precisar enviá-las para a [App Store Oficial do Umbrel](https://github.com/getumbrel/umbrel-apps).

## Como usar:

1. Comece clicando no botão **"Use this template"** localizado acima.
2. Defina um ID e um nome para sua app store no arquivo `umbrel-app-store.yml`. Esse arquivo especifica dois atributos importantes:
    - `id` – Atua como um prefixo único para todos os apps da sua App Store Comunitária. Você deve iniciar o ID de cada aplicativo com o ID da sua app store. Por exemplo, neste template, o ID da app store é `sparkles` e existe um app chamado `hello world`. Portanto, o ID do app deve ser: `sparkles-hello-world`.
    - `name` – Este é o nome da App Store Comunitária exibido na interface do umbrelOS.
3. Altere o nome da pasta `sparkles-hello-world` para corresponder ao ID do seu aplicativo. O ID do app fica a seu critério. Por exemplo, se o ID da sua app store for `whistles` e seu app se chamar *My Video Downloader*, você pode definir o ID do app como `whistles-my-video-downloader` e renomear a pasta de acordo.
4. Em seguida, preencha os detalhes de listagem do seu app no arquivo `whistles-my-video-downloader/umbrel-app.yml`. Essas informações são exibidas na interface do umbrelOS.
5. Inclua os serviços Docker necessários no arquivo `whistles-my-video-downloader/docker-compose.yml`.
6. Pronto! Sua App Store Comunitária, com seu aplicativo exclusivo, agora está configurada e pronta para uso. Para utilizá-la, você pode adicionar a URL do GitHub da sua App Store Comunitária na interface do umbrelOS, conforme mostrado na demonstração a seguir:

https://user-images.githubusercontent.com/10330103/197889452-e5cd7e96-3233-4a09-b475-94b754adc7a3.mp4
