// BridgEddy — textos em português, inglês e espanhol
// © 2026 Eddy Antonini — MIT License

import Foundation

let supportedLangs = ["pt", "en", "es"]

/// Primeiro idioma preferido do sistema que o app suporta; senão, inglês.
let currentLang: String = {
    for l in Locale.preferredLanguages {
        let code = String(l.prefix(2))
        if supportedLangs.contains(code) { return code }
    }
    return "en"
}()

func L(_ key: String) -> String {
    strings[key]?[currentLang] ?? strings[key]?["en"] ?? key
}

func Lf(_ key: String, _ args: CVarArg...) -> String {
    String(format: L(key), arguments: args)
}

let strings: [String: [String: String]] = [
    // Janela principal
    "appSubtitle": ["pt": "Abre a sessão de outro usuário deste Mac numa janela.",
                    "en": "Opens another user's session on this Mac in a window.",
                    "es": "Abre la sesión de otro usuario de este Mac en una ventana."],
    "user": ["pt": "Usuário", "en": "User", "es": "Usuario"],
    "connect": ["pt": "Conectar", "en": "Connect", "es": "Conectar"],
    "noUsers": ["pt": "Nenhum outro usuário encontrado neste Mac.",
                "en": "No other users found on this Mac.",
                "es": "No se encontraron otros usuarios en este Mac."],
    "preparing": ["pt": "Preparando…", "en": "Preparing…", "es": "Preparando…"],
    "enablingServices": ["pt": "Ligando os serviços…", "en": "Turning services on…", "es": "Activando los servicios…"],
    "openingTunnel": ["pt": "Abrindo o túnel…", "en": "Opening the tunnel…", "es": "Abriendo el túnel…"],
    "bridgeOpen": ["pt": "Ponte aberta", "en": "Bridge open", "es": "Puente abierto"],
    "loginHint": ["pt": "Na janela de login, entre como **%@** e escolha abrir uma sessão própria. O nome já está copiado: é só colar com ⌘V.",
                  "en": "In the login window, sign in as **%@** and choose to open a separate session. The name is already copied: just paste it with ⌘V.",
                  "es": "En la ventana de inicio de sesión, entra como **%@** y elige abrir una sesión propia. El nombre ya está copiado: solo pégalo con ⌘V."],
    "closeHint": ["pt": "Ao fechar a janela do Compartilhamento de Tela, eu desfaço tudo sozinho.",
                  "en": "When you close the Screen Sharing window, I undo everything on my own.",
                  "es": "Al cerrar la ventana de Compartir Pantalla, lo deshago todo solo."],
    "disconnect": ["pt": "Desconectar e desfazer", "en": "Disconnect and undo", "es": "Desconectar y deshacer"],
    "done": ["pt": "Pronto. Tudo foi desfeito.", "en": "Done. Everything was undone.", "es": "Listo. Todo se deshizo."],
    "noConnection": ["pt": "Nenhuma conexão em 3 minutos. Desfiz tudo.",
                     "en": "No connection in 3 minutes. Everything was undone.",
                     "es": "Ninguna conexión en 3 minutos. Todo se deshizo."],

    // Erro "não permitido no localhost"
    "localhostTitle": ["pt": "A conexão caiu logo depois do login",
                       "en": "The connection dropped right after login",
                       "es": "La conexión se cayó justo después del inicio de sesión"],
    "localhostText": ["pt": "Se apareceu “não é permitido no localhost”, o Compartilhar Tela travou. Reiniciar resolve, e eu abro a janela de novo.",
                      "en": "If you saw “not permitted on localhost”, Screen Sharing got stuck. Restarting it fixes that, and I'll open the window again.",
                      "es": "Si apareció “no está permitido en localhost”, Compartir Pantalla se trabó. Reiniciarlo lo soluciona y vuelvo a abrir la ventana."],
    "restartSharing": ["pt": "Reiniciar o Compartilhar Tela", "en": "Restart Screen Sharing", "es": "Reiniciar Compartir Pantalla"],

    // Serviços
    "svcScreen": ["pt": "Compartilhar Tela", "en": "Screen Sharing", "es": "Compartir Pantalla"],
    "svcRemote": ["pt": "Acesso Remoto", "en": "Remote Login", "es": "Sesión remota"],
    "adminPromptEnable": ["pt": "O BridgEddy vai ligar o Compartilhar Tela e o Acesso Remoto só enquanto você estiver conectado.",
                          "en": "BridgEddy will turn on Screen Sharing and Remote Login only while you are connected.",
                          "es": "BridgEddy activará Compartir Pantalla y Sesión remota solo mientras estés conectado."],
    "adminPromptRestart": ["pt": "O BridgEddy vai reiniciar o Compartilhar Tela.",
                           "en": "BridgEddy will restart Screen Sharing.",
                           "es": "BridgEddy reiniciará Compartir Pantalla."],
    "adminPromptSSHOff": ["pt": "O BridgEddy vai desligar o Acesso Remoto (SSH).",
                          "en": "BridgEddy will turn off Remote Login (SSH).",
                          "es": "BridgEddy desactivará la Sesión remota (SSH)."],

    // Erros
    "errServices": ["pt": "Não consegui ligar os serviços: %@", "en": "Couldn't turn the services on: %@", "es": "No pude activar los servicios: %@"],
    "errBlocked": ["pt": "O macOS não deixou ligar: %@. Ative no painel que abri e clique em Conectar de novo.",
                   "en": "macOS didn't allow turning on: %@. Turn it on in the panel I opened and click Connect again.",
                   "es": "macOS no permitió activar: %@. Actívalo en el panel que abrí y haz clic en Conectar de nuevo."],
    "errNoPort": ["pt": "Nenhuma porta livre entre 5901 e 5910.", "en": "No free port between 5901 and 5910.", "es": "Ningún puerto libre entre 5901 y 5910."],
    "errKey": ["pt": "Não consegui criar a chave temporária: %@", "en": "Couldn't create the temporary key: %@", "es": "No pude crear la clave temporal: %@"],
    "errSSH": ["pt": "Não consegui iniciar o SSH: %@", "en": "Couldn't start SSH: %@", "es": "No pude iniciar SSH: %@"],
    "errTunnelClosed": ["pt": "O túnel fechou: %@", "en": "The tunnel closed: %@", "es": "El túnel se cerró: %@"],
    "errTunnelTimeout": ["pt": "O túnel não abriu a tempo.", "en": "The tunnel didn't open in time.", "es": "El túnel no se abrió a tiempo."],
    "errRestart": ["pt": "Não consegui reiniciar o Compartilhar Tela: %@", "en": "Couldn't restart Screen Sharing: %@", "es": "No pude reiniciar Compartir Pantalla: %@"],
    "errOldSetup": ["pt": "Não consegui remover a chave antiga: %@", "en": "Couldn't remove the old key: %@", "es": "No pude eliminar la clave antigua: %@"],
    "errSSHOff": ["pt": "Não consegui desligar o Acesso Remoto: %@", "en": "Couldn't turn off Remote Login: %@", "es": "No pude desactivar la Sesión remota: %@"],

    // Limpeza da configuração manual antiga
    "oldSetupTitle": ["pt": "Remover a configuração antiga?", "en": "Remove the old setup?", "es": "¿Eliminar la configuración antigua?"],
    "oldSetupText": ["pt": "Existe uma chave SSH fixa da configuração manual antiga autorizada na sua conta. O BridgEddy cria uma chave nova a cada conexão e apaga no fim, então a antiga pode sair.",
                     "en": "There's a permanent SSH key from the old manual setup authorized on your account. BridgEddy creates a new key for each connection and deletes it afterwards, so the old one can go.",
                     "es": "Hay una clave SSH fija de la configuración manual antigua autorizada en tu cuenta. BridgEddy crea una clave nueva en cada conexión y la borra al final, así que la antigua puede salir."],
    "remove": ["pt": "Remover", "en": "Remove", "es": "Eliminar"],
    "keep": ["pt": "Manter", "en": "Keep", "es": "Mantener"],
    "sshOffTitle": ["pt": "Deixar o Acesso Remoto (SSH) desligado no dia a dia?",
                    "en": "Keep Remote Login (SSH) off day to day?",
                    "es": "¿Dejar la Sesión remota (SSH) desactivada en el día a día?"],
    "sshOffText": ["pt": "O BridgEddy liga o Acesso Remoto só durante a conexão e desliga depois. Se você não usa SSH para mais nada, pode desligá-lo agora.",
                   "en": "BridgEddy turns Remote Login on only during the connection and off afterwards. If you don't use SSH for anything else, you can turn it off now.",
                   "es": "BridgEddy activa la Sesión remota solo durante la conexión y la desactiva después. Si no usas SSH para nada más, puedes desactivarla ahora."],
    "turnOff": ["pt": "Desligar", "en": "Turn off", "es": "Desactivar"],
    "keepOn": ["pt": "Manter ligado", "en": "Keep on", "es": "Mantener activado"],

    // Apoio (mesmo card do Backeddy)
    "supportBtn": ["pt": "Apoiar o projeto", "en": "Support the project", "es": "Apoyar el proyecto"],
    "supportTitle": ["pt": "Apoie o BridgEddy", "en": "Support BridgEddy", "es": "Apoya BridgEddy"],
    "supportSubtitle": ["pt": "O BridgEddy é gratuito e de código aberto. Se ele te ajudou, considere uma doação de agradecimento — qualquer valor ajuda a manter o projeto.",
                        "en": "BridgEddy is free and open source. If it helped you, consider a thank-you donation — any amount helps keep the project going.",
                        "es": "BridgEddy es gratuito y de código abierto. Si te ayudó, considera una donación de agradecimiento — cualquier monto ayuda a mantener el proyecto."],
    "pixTitle": ["pt": "PIX (Brasil)", "en": "PIX (Brazil)", "es": "PIX (Brasil)"],
    "pixHint": ["pt": "Aponte a câmera do app do seu banco para o QR code e escolha o valor, ou copie a chave.",
                "en": "Point your Brazilian bank app's camera at the QR code and choose the amount, or copy the key.",
                "es": "Apunta la cámara de la app de tu banco brasileño al código QR y elige el monto, o copia la clave."],
    "pixKeyLabel": ["pt": "Chave: %@", "en": "Key: %@", "es": "Clave: %@"],
    "copyKey": ["pt": "Copiar chave", "en": "Copy key", "es": "Copiar clave"],
    "copyPixCode": ["pt": "Copiar PIX copia e cola", "en": "Copy PIX code", "es": "Copiar código PIX"],
    "copied": ["pt": "Copiado!", "en": "Copied!", "es": "¡Copiado!"],
    "intlTitle": ["pt": "De outros países", "en": "From other countries", "es": "Desde otros países"],
    "intlHint": ["pt": "Pelo GitHub Sponsors, com cartão — sem taxas para o desenvolvedor.",
                 "en": "Via GitHub Sponsors, by card — no fees for the developer.",
                 "es": "A través de GitHub Sponsors, con tarjeta — sin comisiones para el desarrollador."],
    "starRepo": ["pt": "Dar uma estrela", "en": "Star the repo", "es": "Dar una estrella"],
    "supportThanks": ["pt": "Obrigado! Indicar o app para amigos e dar uma estrela no GitHub também ajuda muito. — Eddy Antonini",
                      "en": "Thank you! Telling friends about the app and starring it on GitHub helps a lot too. — Eddy Antonini",
                      "es": "¡Gracias! Recomendar la app a tus amigos y darle una estrella en GitHub también ayuda mucho. — Eddy Antonini"],
    "close": ["pt": "Fechar", "en": "Close", "es": "Cerrar"],
]
