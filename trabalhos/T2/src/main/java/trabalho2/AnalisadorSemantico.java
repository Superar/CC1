package trabalho2;

/**
 * Created by marcio on 08/07/17.
 */

public class AnalisadorSemantico extends LuazinhaBaseListener
{
    PilhaDeTabelas escopos = new PilhaDeTabelas();

    @Override
    public void enterPrograma(LuazinhaParser.ProgramaContext ctx)
    {
        // Escopo global e empilhado e analisador entra em Trecho
        TabelaDeSimbolos escopoGlobal = new TabelaDeSimbolos("global");
        escopos.empilhar(escopoGlobal);
        enterTrecho(ctx.trecho());
        // Ao terminar o programa, o escopo global e desempilhado
        escopos.desempilhar();
    }

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

    @Override
    public void enterBloco(LuazinhaParser.BlocoContext ctx)
    {
        enterTrecho(ctx.trecho());
    }

    @Override
    public void enterComando(LuazinhaParser.ComandoContext ctx)
    {

        // Existem variaveis sendo atribuidas
        if (ctx.listavar() != null)
        {
            // Verifica o lado direito da atribuicao primeiro
            // Pois uma variavel pode estar sendo utilizada em sua propria atribuicao
            enterListaexp(ctx.listaexp());

            // Adiciona todas as variáveis em listavar como variaveis
            for (String nome : ctx.listavar().nomes)
            {
                // Variavel so e criada se nao existir
                if (!escopos.existeSimbolo(nome))
                {
                    escopos.topo().adicionarSimbolo(nome, "variavel");
                }
            }
        }

        // O comando eh uma chamada de funcao
        if (ctx.chamadadefuncao() != null)
        {
            enterChamadadefuncao(ctx.chamadadefuncao());
        }

        // O comando eh um bloco de repeticao while
        if (ctx.whileToken != null)
        {
            enterExp(ctx.expWhile);
            enterBloco(ctx.blocoWhile);
        }

        // O comando e uma estrutura do tipo repeat
        if (ctx.blocoRepeat != null)
        {
            enterBloco(ctx.blocoRepeat);
        }

        // O comando eh um bloco condicional (if)
        if (ctx.expIf != null)
        {
            enterExp(ctx.expIf);
            enterBloco(ctx.blocoIf);

            for (LuazinhaParser.ExpContext exp : ctx.expElseIf)
            {
                enterExp(exp);
            }

            for (LuazinhaParser.BlocoContext bloco : ctx.blocoElseIf)
            {
                enterBloco(bloco);
            }

            if (ctx.blocoElse != null)
            {
                enterBloco(ctx.blocoElse);
            }
        }

        // O comando eh um loop do tipo for
        else if (ctx.for1 != null || ctx.for2 != null)
        {
            TabelaDeSimbolos escopoFor = new TabelaDeSimbolos("for");
            escopos.empilhar(escopoFor);

            // for1
            if (ctx.for1 != null)
            {
                escopos.topo().adicionarSimbolo(ctx.NOME().getText(), "variavel");
                enterBloco(ctx.blocoFor1);
            }
            // for2
            else
            {
                escopos.topo().adicionarSimbolos(ctx.listadenomes().nomes, "variavel");
                enterBloco(ctx.blocoFor2);
            }

            escopos.desempilhar();
        }

        // Existe uma funcao sendo declarada
        else if (ctx.corpodafuncao() != null)
        {
            // Cria o escopo da funcao
            TabelaDeSimbolos escopoFuncao;
            // Verifica qual nome deve ser utilizado
            if (ctx.nomedafuncao() != null)
            {
                escopoFuncao = new TabelaDeSimbolos(ctx.nomedafuncao().nome);
            } else
            {
                escopoFuncao = new TabelaDeSimbolos(ctx.NOME().getText());
            }
            escopos.empilhar(escopoFuncao);
            enterCorpodafuncao(ctx.corpodafuncao());
            // Ao se terminar a funcao, o escopo e desempilhado
            escopos.desempilhar();
        }

        else if (ctx.varLocal != null)
        {
            escopos.topo().adicionarSimbolos(ctx.listadenomes().nomes, "variavel");
            enterListaexp(ctx.listaexp());
        }
    }


    @Override
    public void enterCorpodafuncao(LuazinhaParser.CorpodafuncaoContext ctx)
    {
        // Funcao possui parametros que devem ser inseridos na tabela de simbolos
        if (ctx.listapar() != null)
        {
            enterListapar(ctx.listapar());
        }

        enterBloco(ctx.bloco());
    }

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

    // Lista de expressoes do lado direito da atribuicao de variaveis
    @Override
    public void enterListaexp(LuazinhaParser.ListaexpContext ctx)
    {
        // Entra em todas as expressoes da lista
        for (LuazinhaParser.ExpContext exp : ctx.listaExp)
        {
            enterExp(exp);
        }

        // Entra na ultima expressao
        if (ctx.ultimaExp != null)
        {
            enterExp(ctx.ultimaExp);
        }
    }

    @Override
    public void enterExp(LuazinhaParser.ExpContext ctx)
    {
        // Verifica se existe expprefixo2, isto eh, uma variavel do lado direito da atribuicao
        if (ctx.expprefixo2() != null)
        {
            enterExpprefixo2(ctx.expprefixo2());
        }

        // A regra exp opbin exp foi reconhecida
        if (ctx.opbin() != null)
        {
            enterExp(ctx.opbinExp1);
            enterExp(ctx.opBinExp2);
        }
    }

    @Override
    public void enterExpprefixo2(LuazinhaParser.Expprefixo2Context ctx)
    {
        // A variavel do lado direito da atribuicao existe
        if (ctx.var() != null)
        {
            // Se nao esta no esocpo, uma mensagem de erro deve ser mostrada
            LuazinhaParser.VarContext var = ctx.var();
            if (!escopos.existeSimbolo(var.nome))
            {
                Mensagens.erroVariavelNaoExiste(var.linha, var.coluna, var.nome);
            }
        }

        if (ctx.chamadadefuncao() != null)
        {
            enterChamadadefuncao(ctx.chamadadefuncao());
        }
    }

    @Override
    public void enterChamadadefuncao(LuazinhaParser.ChamadadefuncaoContext ctx)
    {
        if (ctx.args() != null)
        {
            enterArgs(ctx.args());
        }
    }

    @Override
    public void enterArgs(LuazinhaParser.ArgsContext ctx)
    {
        if (ctx.listaexp() != null)
        {
            enterListaexp(ctx.listaexp());
        }
    }

    @Override
    public void enterUltimocomando(LuazinhaParser.UltimocomandoContext ctx)
    {
        if (ctx.listaexp() != null)
        {
            enterListaexp(ctx.listaexp());
        }
    }
}

