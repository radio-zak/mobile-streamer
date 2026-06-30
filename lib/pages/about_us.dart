import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        scrolledUnderElevation: 0.0,
        title: Text('O nas', style: Theme.of(context).textTheme.headlineMedium),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Studenckie Radio “ŻAK” Politechniki Łódzkiej ',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        TextSpan(
                          text:
                              'należy do jednych z najstarszych rozgłośni akademickich w Polsce. Można nas słuchać na częstotliwości 88,8 MHz w Łodzi i okolicach, a przez Internet na całym świecie. Żak jest jedyną radiostacją w Polsce w pełni zarządzaną przez samych studentów, którzy za swą pracę nie pobierają wynagrodzenia, bowiem nasza działalność opiera się na wolontariacie. Nasza ramówka może poszczycić się programami autorskimi o tematyce kulturalnej, społecznej, muzycznej, sportowej i publicystycznej.',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text:
                          'Oprócz działań stricte radiowych, Żak zajmuje się również organizacją i nagłaśnianiem koncertów. Współtworzy lub patronuje takim wydarzeniom, jak np. Ogólnopolski Studencki Przegląd Piosenki Turystycznej YAPA, Explorers Festival, XX Międzynarodowy Festiwal Sztuk Przyjemnych i Nieprzyjemnych. W 2014 roku otrzymaliśmy "Punkt dla Łodzi" w kategorii instytucje.',
                    ),
                  ],
                ),
              ),
              RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      style: Theme.of(context).textTheme.titleMedium,
                      text: 'Informacje o nadawcy\n',
                    ),
                    TextSpan(
                      text: 'Nadawcą programu jest Politechnika Łódzka.',
                    ),
                  ],
                ),
              ),
              RichText(
                textAlign: TextAlign.start,
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(text: 'Adres nadawcy:\n'),
                    TextSpan(text: 'Biuro Rektora Politechniki Łódzkiej\n'),
                    TextSpan(text: 'ul. Ks. I. Skorupki 10/12, 90-924 Łódż'),
                  ],
                ),
              ),
              RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      style: Theme.of(context).textTheme.titleSmall,
                      text: 'Usługi medialne świadczone przez nadawcę: \n',
                    ),
                    TextSpan(
                      text:
                          '\u2022 Program radiowy pn. "Studenckie Radio ŻAK Politechniki Łódzkiej"\n',
                    ),
                    TextSpan(text: '\u2022 Biuletyn "Życie Uczelni"\n'),
                    TextSpan(text: '\u2022 Czasopisma naukowe'),
                  ],
                ),
              ),
              RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text:
                          'Nadawca podlega jurysdykcji Rzeczypospolitej Polskiej. Organem właściwym w sprawach radiofonii i telewizji jest Krajowa Rada Radiofonii i Telewizji.',
                    ),
                  ],
                ),
              ),
              Image.asset(
                'assets/bb2b5b5c9bbaad233d411fd9e90e8f629799c12f.png',
                color: Colors.white,
                alignment: Alignment.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
