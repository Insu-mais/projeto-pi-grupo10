/* Alterna graficos apenas quando a tela e pequena.
   Desktop mostra todos os graficos. Nenhuma rolagem de pagina e necessaria. */
function mostrarGrafico(botao) {
    let botoes = document.querySelectorAll('.aba-grafico');
    let paines = document.querySelectorAll('[data-grafico]');
    let destino = botao.getAttribute('data-abrir');

    for (let i = 0; i < botoes.length; i++) {
        let selecionado = botoes[i] === botao;
        botoes[i].setAttribute('aria-selected', selecionado ? 'true' : 'false');
    }
    for (let i = 0; i < paines.length; i++) {
        paines[i].classList.toggle('painel-ativo', paines[i].getAttribute('data-grafico') === destino);
    }
    // Charts criados em containers escondidos precisam atualizar o tamanho ao aparecer.
    requestAnimationFrame(function () {
        requestAnimationFrame(function () {
            if (typeof Chart !== 'undefined') {
                for (let i = 0; i < paines.length; i++) {
                    let canvas = paines[i].querySelector('canvas');
                    if (canvas && paines[i].classList.contains('painel-ativo')) {
                        let grafico = Chart.getChart(canvas);
                        if (grafico) grafico.resize();
                    }
                }
            }
        });
    });
}
