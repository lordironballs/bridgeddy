<p align="center"><img src="docs/icon.png" width="128" alt="BridgEddy"></p>

<h1 align="center">BridgEddy</h1>

<p align="center">Abra a sessão de outro usuário do mesmo Mac numa janela — e desfaça tudo quando terminar.</p>

<p align="center"><a href="README.md">English</a> · <a href="README.es.md">Español</a></p>

---

## Por quê

O Compartilhamento de Tela do macOS consegue abrir uma **sessão virtual separada** para outro usuário, mas se recusa a conectar no próprio Mac ("não é permitido no localhost"). O jeito clássico de contornar é um túnel SSH digitado no Terminal. O BridgEddy faz isso com um clique.

Útil para quem tem uma conta pessoal e uma de trabalho no mesmo Mac e precisa usar apps das duas ao mesmo tempo.

## O que ele faz

1. Você escolhe o usuário de destino e clica em **Conectar**.
2. Se o **Compartilhar Tela** ou o **Acesso Remoto** estiverem desligados, ele liga (pedindo a senha de administrador uma vez).
3. Cria uma **chave SSH temporária**, restrita a este Mac e só à porta do Compartilhamento de Tela, e abre um túnel local.
4. Abre o Compartilhamento de Tela em `vnc://localhost:590x` e copia o nome do usuário. Entre com a senha dele e escolha abrir uma sessão própria.
5. Quando você fecha a janela do Compartilhamento de Tela, ele **desfaz tudo**: fecha o túnel, apaga a chave e desliga só os serviços que ele mesmo ligou — mesmo se o app fechar ou travar.

Se a conexão cair logo depois do login com "não é permitido no localhost", o Compartilhar Tela travou: o BridgEddy oferece o botão **Reiniciar o Compartilhar Tela** e reconecta.

## Compilar

Precisa do macOS 13+ e das ferramentas de linha de comando do Xcode (`xcode-select --install`).

```bash
./build.sh                 # compila, instala em ~/Applications e abre
SKIP_INSTALL=1 ./build.sh  # só compila em build/
```

## Limitações conhecidas

- A sessão virtual herda os monitores físicos do Mac; use o menu de telas do Compartilhamento de Tela para mostrar só uma.
- Áudio e aceleração gráfica dentro da sessão virtual são limitados.
- Em algumas versões do macOS, ligar o Compartilhar Tela por linha de comando é bloqueado; aí o BridgEddy abre os ajustes de Compartilhamento para você ligar.

## Apoie

O BridgEddy é gratuito e de código aberto. Se ele te ajudou, uma doação de agradecimento mantém o projeto ❤️

- 🇧🇷 **PIX:** `pix@xwa.com.br` (ou **Apoiar o projeto** dentro do app, com QR code)
- 🌎 **[GitHub Sponsors](https://github.com/sponsors/lordironballs)**
- ⭐ Dar uma estrela no repositório e indicar para amigos também ajuda muito!

## Licença

[MIT](LICENSE) © 2026 [Eddy Antonini](https://eddyantonini.com.br)
