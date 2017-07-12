package trabalho2;

/**
 * Created by marcio on 08/07/17.
 */

public class AnalisadorSemantico extends LuazinhaBaseListener
{
    PilhaDeTabelas escopos = new PilhaDeTabelas();

    // programa : trecho
    @Override
    public void enterPrograma(LuazinhaParser.ProgramaContext ctx)
    {
        // Escopo global eh empilhado e analisador entra em Trecho
        TabelaDeSimbolos escopoGlobal = new TabelaDeSimbolos("global");
        escopos.empilhar(escopoGlobal);
        enterTrecho(ctx.trecho());
        // Ao terminar o programa, o escopo global e desempilhado
        escopos.desempilhar();
    }

    // trecho : (comando ';'?)* (ultimocomando ';'?)?
    @Override
    public void enterTrecho(LuazinhaParser.TrechoContext ctx)
    {
        // Para cada comando na lista de comandos
        for (LuazinhaParser.ComandoContext comando : ctx.comando())
        {
            enterComando(comando);
        }

        // ultimocomando e opcional, verifica se esta presente
        if (ctx.ultimocomando() != null)
        {
            enterUltimocomando(ctx.ultimocomando());
        }
    }

    // bloco : trecho
    @Override
    public void enterBloco(LuazinhaParser.BlocoContext ctx)
    {
        enterTrecho(ctx.trecho());
    }

    /* comando :  f '=' listaexp
        |  chamadadefuncao
        |  'do' bloco 'end'
        |  whileToken='while' expWhile=exp 'do' blocoWhile=bloco 'end'
        |  'repeat' blocoRepeat=bloco 'until' exp
        |  'if' expIf=exp 'then' blocoIf=bloco ('elseif' expElseIf+=exp 'then' blocoElseIf+=bloco)* ('else' blocoElse=bloco)? 'end'
        |  for1='for' NOME '=' exp ',' exp (',' exp)? 'do' blocoFor1=bloco 'end'
        |  for2='for' listadenomes 'in' listaexpFor2=listaexp 'do' blocoFor2=bloco 'end'
        |  'function' nomedafuncao corpodafuncao
        |  'local' 'function' NOME corpodafuncao
        |  varLocal='local' listadenomes ('=' listaexp)?
    */
    @Override
    public void enterComando(LuazinhaParser.ComandoContext ctx)
    {

        // listavar '=' listaexp
        // Existem variaveis sendo atribuidas
        if (ctx.listavar() != null)
        {
            // Verifica listaexp primeiro
            // Pois uma variavel pode estar sendo utilizada em sua propria atribuicao
            // Exemplo: k = k + 1
            enterListaexp(ctx.listaexp());

            // Adiciona todas as variáveis em listavar na tabela de simbolos como variaveis
            // Pois elas estao sendo criadas ou utilizadas
            for (String nome : ctx.listavar().nomes)
            {
                // Variavel so e criada se nao existir
                if (!escopos.existeSimbolo(nome))
                {
                    escopos.topo().adicionarSimbolo(nome, "variavel");
                }
            }
        }

        // chamadadefuncao
        // O comando eh uma chamada de funcao
        if (ctx.chamadadefuncao() != null)
        {
            enterChamadadefuncao(ctx.chamadadefuncao());
        }

        // 'while' expWhile=exp 'do' blocoWhile=bloco 'end'
        // O comando eh um bloco de repeticao while
        if (ctx.expWhile != null)
        {
            enterExp(ctx.expWhile);
            enterBloco(ctx.blocoWhile);
        }

        // 'repeat' blocoRepeat=bloco 'until' expRepeat=exp
        // O comando e uma estrutura do tipo repeat
        if (ctx.blocoRepeat != null)
        {
            enterBloco(ctx.blocoRepeat);
            enterExp(ctx.expRepeat);
        }

        // 'if' expIf=exp 'then' blocoIf=bloco ('elseif' expElseIf+=exp 'then' blocoElseIf+=bloco)* ('else' blocoElse=bloco)? 'end'
        // O comando eh um bloco condicional (if)
        if (ctx.expIf != null)
        {
            // expIf=exp
            enterExp(ctx.expIf);
            // blocoIf=bloco
            enterBloco(ctx.blocoIf);

            // ('elseif' expElseIf+=exp 'then' blocoElseIf+=bloco)*
            for (LuazinhaParser.ExpContext exp : ctx.expElseIf)
            {
                enterExp(exp);
            }

            for (LuazinhaParser.BlocoContext bloco : ctx.blocoElseIf)
            {
                enterBloco(bloco);
            }

            // ('else' blocoElse=bloco)?
            if (ctx.blocoElse != null)
            {
                enterBloco(ctx.blocoElse);
            }
        }

        // for1='for' NOME '=' expFor1=exp ',' exp2For1=exp (',' exp3For1=exp)? 'do' blocoFor1=bloco 'end'
        // for2='for' listadenomes 'in' listaexp 'do' blocoFor2=bloco 'end'
        // O comando eh um loop do tipo for
        else if (ctx.for1 != null || ctx.for2 != null)
        {
            // Criacao do escopo
            TabelaDeSimbolos escopoFor = new TabelaDeSimbolos("for");
            escopos.empilhar(escopoFor);

            // for1
            if (ctx.for1 != null)
            {

                escopos.topo().adicionarSimbolo(ctx.NOME().getText(), "variavel");

                // expFor1=exp
                enterExp(ctx.expFor1);

                // exp2For1=exp
                enterExp(ctx.exp2For1);

                // (',' exp3For1=exp)?
                if (ctx.exp3For1 != null)
                {
                    enterExp(ctx.exp3For1);
                }

                enterBloco(ctx.blocoFor1);
            }
            // for2
            else
            {
                enterListaexp(ctx.listaexp());
                escopos.topo().adicionarSimbolos(ctx.listadenomes().nomes, "variavel");
                enterBloco(ctx.blocoFor2);
            }

            // Fim do escopo
            escopos.desempilhar();
        }

        // 'function' nomedafuncao corpodafuncao
        // Existe uma funcao sendo declarada
        else if (ctx.corpodafuncao() != null)
        {
            // Criacao do escopo
            TabelaDeSimbolos escopoFuncao;

            // nomedafuncao
            // Verifica qual nome deve ser utilizado
            if (ctx.nomedafuncao() != null)
            {
                escopoFuncao = new TabelaDeSimbolos(ctx.nomedafuncao().nome);
                escopos.empilhar(escopoFuncao);

                // 'function' nomedafuncao corpodafuncao
                // Se o nome da funcao possui ':', cria-se o parametro self
                if (ctx.nomedafuncao().n3 != null)
                {
                    // Empilha o escopo da funcao, convertendo ':' para '.'
                    escopos.topo().adicionarSimbolo("self", "parametro");
                }
            }
            else
            {
                // Caso contrario, ha apenas o empilhamento dos parametros explicitos da funcao
                escopoFuncao = new TabelaDeSimbolos(ctx.NOME().getText());
                escopos.empilhar(escopoFuncao);
            }


            // corpodafuncao
            enterCorpodafuncao(ctx.corpodafuncao());

            // Fim do escopo
            escopos.desempilhar();
        }

        // varLocal='local' listadenomes ('=' listaexp)?
        else if (ctx.varLocal != null)
        {
            // listadenomes
            escopos.topo().adicionarSimbolos(ctx.listadenomes().nomes, "variavel");

            // ('=' listaexp)?
            if (ctx.listaexp() != null)
            {
                enterListaexp(ctx.listaexp());
            }
        }
    }

    // corpodafuncao : '(' (listapar)? ')' bloco 'end'
    @Override
    public void enterCorpodafuncao(LuazinhaParser.CorpodafuncaoContext ctx)
    {
        // Funcao possui parametros
        if (ctx.listapar() != null)
        {
            enterListapar(ctx.listapar());
        }

        enterBloco(ctx.bloco());
    }

    // listapar : listadenomes (',' '...')?
    @Override
    public void enterListapar(LuazinhaParser.ListaparContext ctx)
    {
        // Se existirem parametros no formato de nomes, serao inseridos a tabela
        if (ctx.listadenomes() != null)
        {
            for (String nome : ctx.listadenomes().nomes)
            {
                if (!escopos.topo().existeSimbolo(nome))
                {
                    escopos.topo().adicionarSimbolo(nome, "parametro");
                }
            }
        }
    }

    // (listaExp+=exp ',')* ultimaExp=exp
    // Lista de expressoes do lado direito da atribuicao de variaveis
    @Override
    public void enterListaexp(LuazinhaParser.ListaexpContext ctx)
    {
        // (listaExp+=exp ',')*
        // Entra em todas as expressoes da lista
        for (LuazinhaParser.ExpContext exp : ctx.listaExp)
        {
            enterExp(exp);
        }

        //

        // ultimaExp=exp
        // Entra na ultima expressao
        if (ctx.ultimaExp != null)
        {
            enterExp(ctx.ultimaExp);
        }
    }

    /* exp :  'nil' | 'false' | 'true' | NUMERO | CADEIA | '...' | funcao |
    expprefixo2 | construtortabela | opbinExp1=exp opbin opBinExp2=exp | opunaria exp
    */
    @Override
    public void enterExp(LuazinhaParser.ExpContext ctx)
    {
        // opbinExp1=exp opbin opBinExp2=exp
        if (ctx.opbin() != null)
        {
            enterExp(ctx.opbinExp1);
            enterExp(ctx.opBinExp2);
        }

        // expprefixo2
        if (ctx.expprefixo2() != null)
        {
            enterExpprefixo2(ctx.expprefixo2());
        }
    }

    // expprefixo2 : var | chamadadefuncao | '(' exp ')'
    @Override
    public void enterExpprefixo2(LuazinhaParser.Expprefixo2Context ctx)
    {
        // var
        if (ctx.var() != null)
        {
            if (!escopos.existeSimbolo(ctx.var().nome))
            {
                Mensagens.erroVariavelNaoExiste(ctx.var().linha, ctx.var().coluna, ctx.var().nome);
            }
        }

        // chamadadefuncao
        if (ctx.chamadadefuncao() != null)
        {
            enterChamadadefuncao(ctx.chamadadefuncao());
        }

        // '(' exp ')'
        if (ctx.exp() != null)
        {
            enterExp(ctx.exp());
        }
    }

    /* chamadadefuncao :  expprefixo args
                          expprefixo ':' NOME args
    */
    @Override
    public void enterChamadadefuncao(LuazinhaParser.ChamadadefuncaoContext ctx)
    {
        // args
        if (ctx.args() != null)
        {
            enterArgs(ctx.args());
        }
    }

    // args :  '(' (listaexp)? ')' | construtortabela | CADEIA
    @Override
    public void enterArgs(LuazinhaParser.ArgsContext ctx)
    {
        // '(' (listaexp)? ')'
        if (ctx.listaexp() != null)
        {
            enterListaexp(ctx.listaexp());
        }
    }

    // ultimocomando : 'return' (listaexp)? | 'break'
    @Override
    public void enterUltimocomando(LuazinhaParser.UltimocomandoContext ctx)
    {
        // 'return' (listaexp)?
        if (ctx.listaexp() != null)
        {
            enterListaexp(ctx.listaexp());
        }
    }

    @Override
    public void enterVar(LuazinhaParser.VarContext ctx)
    {
        // Verificacao de amarracao da variavel, caso ela nao esteja amarrada, exibe-se um erro
        if(!escopos.existeSimbolo(ctx.nome))
        {
            Mensagens.erroVariavelNaoExiste(ctx.linha, ctx.coluna, ctx.nome);
        }
    }
}

