Os parâmetros da função .json do Express configuram como o middleware deve tratar o corpo (body) das requisições com conteúdo JSON. Veja o que cada parâmetro faz:

- inflate  
  Habilita ou desabilita o processamento de corpos comprimidos (deflated). Quando está desabilitado, corpos comprimidos são rejeitados.  
  Tipo: Boolean  
  Padrão: true

- limit  
  Controla o tamanho máximo permitido para o corpo da requisição. Pode ser um número (representando o número de bytes) ou uma string, que é interpretada pela biblioteca de bytes (ex.: "100kb").  
  Tipo: Misto  
  Padrão: "100kb"

- reviver  
  O parâmetro reviver é passado diretamente para o JSON.parse como segundo argumento. Ele permite transformar os valores antes da conversão final para objeto. Consulte a documentação do MDN sobre JSON.parse para mais detalhes.  
  Tipo: Function  
  Padrão: null

- strict  
  Define se apenas arrays e objetos são aceitos. Quando desabilitado, a conversão aceita qualquer valor que JSON.parse consiga interpretar.  
  Tipo: Boolean  
  Padrão: true

- type  
  Determina quais tipos de conteúdo/mídia serão analisados pelo middleware. Pode ser uma string, um array de strings ou uma função. Se não for uma função, o valor é passado para a biblioteca type-is, permitindo especificar, por exemplo, uma extensão ("json"), um tipo mime ("application/json") ou um tipo com wildcard ("_/_"). Se for uma função, ela é chamada com o request (req) e, se retornar um valor truthy, o corpo será analisado.  
  Tipo: Misto  
  Padrão: "application/json"

- verify  
  Uma função de verificação que, se fornecida, é chamada como verify(req, res, buf, encoding). Aqui, buf é um Buffer com o corpo bruto da requisição e encoding é a codificação utilizada. Essa função pode abortar a análise lançando um erro.  
  Tipo: Function  
  Padrão: undefined

---

Express.static é uma função de middleware embutida no Express que serve arquivos estáticos a partir de um diretório raiz fornecido. Ela baseia-se no módulo serve-static e combina a URL da requisição (req.url) com o diretório raiz para localizar e retornar o arquivo solicitado. Se o arquivo não for encontrado, em vez de retornar um erro 404, o middleware chama next() para passar o controle para o próximo middleware na cadeia, permitindo a criação de fallbacks ou encadeamento de middlewares.

A seguir, uma tabela com as propriedades do objeto de opções:

| Propriedade  | Descrição                                                                                                                                       | Tipo     | Padrão       |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------ |
| dotfiles     | Define como arquivos ou diretórios iniciados por ponto (.) serão tratados.                                                                      | String   | "ignore"     |
| etag         | Habilita ou desabilita a geração de ETags (sempre são gerados ETags fracos).                                                                    | Boolean  | true         |
| extensions   | Define as extensões de arquivo que serão utilizadas como fallback se um arquivo não for encontrado. Por exemplo: ['html', 'htm'].               | Misto    | false        |
| fallthrough  | Permite que erros do cliente passem adiante como requisições não tratadas (caso contrário, um erro do cliente seria encaminhado imediatamente). | Boolean  | true         |
| immutable    | Habilita ou desabilita a diretiva immutable no cabeçalho Cache-Control. Quando ativado, o maxAge também deve ser especificado.                  | Boolean  | false        |
| index        | Define o arquivo índice a ser enviado quando o caminho requisitado é um diretório. Pode ser desabilitado definindo como false.                  | Misto    | "index.html" |
| lastModified | Adiciona o cabeçalho Last-Modified com a data de modificação do arquivo no sistema operacional.                                                 | Boolean  | true         |
| maxAge       | Define a propriedade max-age do cabeçalho Cache-Control, em milissegundos ou como uma string no formato ms.                                     | Number   | 0            |
| redirect     | Quando o caminho é um diretório, redireciona para uma URL com barra (trailing "/").                                                             | Boolean  | true         |
| setHeaders   | Função para definir cabeçalhos HTTP personalizados ao servir o arquivo.                                                                         | Function | undefined    |
