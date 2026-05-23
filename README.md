\# Albummer



> Download de sessões fotográficas do Alboompro em alta resolução, direto do terminal.



!\[PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell\&logoColor=white)

!\[Plataforma](https://img.shields.io/badge/Plataforma-Windows-0078D6?logo=windows\&logoColor=white)

!\[Licença](https://img.shields.io/badge/Licen%C3%A7a-MIT-22c55e)



\---



\## O que é



O Alboompro exibe as fotos de prova em baixa resolução (600px). Cada URL segue um padrão fixo — só o parâmetro `width` muda para controlar o tamanho da imagem.



O Albummer aproveita isso: você cola as URLs de preview, escolhe a pasta de destino, e ele converte e baixa todas as fotos em \*\*3840px\*\* automaticamente.



Sem instalação. Sem dependências. Só Windows.



\---



\## Como usar



Abra o PowerShell e execute:



```powershell

irm https://raw.githubusercontent.com/SEU\_USUARIO/albummer/main/albummer.ps1 | iex

```



O script vai guiar você em dois passos:



\*\*Passo 1 — Cole as URLs\*\*



Uma caixa de texto abre. Cole todas as URLs do Alboompro de uma vez (uma por linha) e clique em OK.



\*\*Passo 2 — Escolha a pasta\*\*



Um seletor de pasta nativo do Windows abre. Escolha onde as fotos serão salvas.



Pronto — o download começa com barra de progresso no terminal.



\---



\## Como coletar as URLs no navegador



1\. Abra o álbum no Alboompro

2\. Pressione `F12` para abrir o DevTools

3\. Vá na aba \*\*Network\*\*

4\. Filtre por `images-proof.alboompro.com`

5\. Navegue pelas fotos — as URLs aparecem na lista

6\. Selecione todas, copie e cole no Albummer



\---



\## Como funciona



```

irm URL | iex

&#x20; → InputBox gráfico (colar URLs)

&#x20; → FolderBrowserDialog (escolher pasta)

&#x20; → Conversão /width/600/ → /width/3840/

&#x20; → Download sequencial com progresso

&#x20; → Relatório final

```



O script valida cada URL (domínio correto, tamanho mínimo do arquivo) e reporta falhas ao final sem interromper o restante do download.



\---



\## Pré-requisitos



\- Windows 10 ou superior

\- PowerShell 5.1+ (já vem instalado no Windows 10/11)

\- Conexão com a internet



\---



\## Política de execução



Se o PowerShell bloquear a execução do script, rode antes:



```powershell

Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

```



\---



\## Estrutura do repositório



```

albummer/

├── albummer.ps1   ← script principal

├── README.md

└── LICENSE

```



\---



\## Contribuindo



Pull requests são bem-vindos. Para mudanças maiores, abra uma issue primeiro.



1\. Fork o repositório

2\. Crie sua branch (`git checkout -b feature/sua-feature`)

3\. Commit suas mudanças (`git commit -m 'feat: descrição'`)

4\. Push para a branch (`git push origin feature/sua-feature`)

5\. Abra um Pull Request



\---



\## Licença



MIT — veja \[LICENSE](LICENSE) para detalhes.

