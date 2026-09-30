# O ML Kit acha os seus componentes pelo nome, no manifesto, e cria cada um
# por reflexão, pelo construtor sem argumentos.
#
# A regra que vem com a biblioteca (`firebase-components`) guarda a classe e
# deixa o construtor ir embora: no modo em que o R8 roda hoje, guardar a
# classe já não guarda o construtor dela. Sem o construtor o componente não
# nasce, o leitor de comprovantes fica sem onde se apoiar, e o app **fecha ao
# abrir** — só na versão de uso, que é a única que passa pelo R8. Foi o
# primeiro teste dela num aparelho que mostrou.
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    <init>();
}
