// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:projeto_spotify/Utils/controle_arquivo.dart';

import 'package:spotify/spotify.dart';
import 'package:projeto_spotify/Utils/constants.dart';

import '../Utils/database.dart';
import '../Utils/groups.dart';
import '../Utils/load_screen.dart';

// Classe para realizar a troca da Lista e Mixes.
class TrocarPlaylist extends StatefulWidget {
  final Groups group;

  const TrocarPlaylist({
    super.key,
    required this.group,
  });

  @override
  State<TrocarPlaylist> createState() => _TrocarPlaylistState();
}

class _TrocarPlaylistState extends State<TrocarPlaylist> {
  // Pega os ID's e cria uma lista com os nomes das playlist's.
  Future<Set<Map<String, String>>> getNameFromSpotify(
      List<String> listID, Set<Map<String, String>> newList) async {
    if (listID.isEmpty) {
      return {};
    }

    final credentials =
        SpotifyApiCredentials(Constants.clientId, Constants.clientSecret);
    final spotify = SpotifyApi(credentials);

    for (int index = 0; index != listID.length; index++) {
      await spotify.playlists.get(listID[index]).then((value) {
        try {
          newList.add({
            'name': value.name!,
            'cover': value.images!.first.url!,
            'spotify': value.id!
          });
        } catch (error) {
          newList.remove(newList.elementAt(index));
          index -= 1;
        }
      });
    }

    return newList;
  }

  // Inicia o Controle de Arquivo.
  final storage = ControleArquivo();

  // Controle de Texto para o TextFormField.
  late TextEditingController controller;

  // Backup da database.
  dynamic databaseBackup = {};

  // Cria um Texto personalizado com o botão de deletar no lado.
  Widget rowText(String file, Size size, int index) {
    Set<Map<String, String>> name = {};

    switch (file) {
      case 'list':
        name = widget.group.listMap;
      case 'mixes':
        name = widget.group.mixesMap;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: size.width * 0.60,
          child: Text(
            name.elementAt(index)['name'] ?? '',
            style: TextStyle(color: Colors.white, fontSize: size.width * 0.05),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(
          onPressed: () async {
            LoadScreen().loadingScreen(context);

            Set<Map<String, String>> removeMap = {};

            switch (file) {
              case 'list':
                removeMap = widget.group.listMap;

              case 'mixes':
                removeMap = widget.group.mixesMap;
            }

            await storage.update(file, removeMap.elementAt(index)['spotify']!);

            await storage.readCounter(file).then((value) {
              switch (file) {
                case 'list':
                  widget.group.list = value;

                case 'mixes':
                  widget.group.mixes = value;
              }
            }).then((value) {
              switch (file) {
                case 'list':
                  widget.group.listMap
                      .remove(widget.group.listMap.elementAt(index));

                case 'mixes':
                  widget.group.mixesMap
                      .remove(widget.group.mixesMap.elementAt(index));
              }

              setState(() {});

              Navigator.of(context).pop();
            });
          },
          child: const Icon(
            Icons.close,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  // Botão de adicionar personalizado.
  Future<void> add(Size size, String file) {
    String hint = '';

    switch (file) {
      case 'list':
        hint = 'da Lista';
      case 'mixes':
        hint = 'do Mix';
    }

    return showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: Colors.transparent,
            actions: [
              TextField(
                decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Coloque o ID $hint'),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: size.height * 0.02,
                ),
                cursorColor: Colors.white,
                keyboardType: TextInputType.text,
                controller: controller,
                onSubmitted: (String value) async {
                  if (value != '') {
                    LoadScreen().loadingScreen(context);

                    final credentials = SpotifyApiCredentials(
                        Constants.clientId, Constants.clientSecret);
                    final spotify = SpotifyApi(credentials);

                    try {
                      await spotify.playlists
                          .get(value)
                          .then((valueSpotify) {});

                      await ControleArquivo().writeAdd(file, value);

                      await ControleArquivo().readCounter(file).then((value) {
                        switch (file) {
                          case 'list':
                            widget.group.list = value;
                          case 'mixes':
                            widget.group.mixes = value;
                        }
                      });

                      await getNameFromSpotify(widget.group.get(file), {})
                          .then((value) {
                        switch (file) {
                          case 'list':
                            widget.group.listMap = value;
                          case 'mixes':
                            widget.group.mixesMap = value;
                        }

                        setState(() {});
                      });

                      Navigator.of(context).pop();
                      controller.text = '';
                    } catch (error) {
                      // caso não encontre a playlist volta para o textField.
                    }
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        });
  }

  @override
  void initState() {
    super.initState();
    // Atribuindo o Editor de Texto.
    controller = TextEditingController();
  }

  // Função do Flutter para quando a Página fechar.
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pega o tamanho da tela e armazena.
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Trocar Playlist',
          style: TextStyle(
            color: Colors.white,
            fontSize: size.width * 0.065,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () {
                // Mostra um pop-up.
                showDialog(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.5),
                    builder: (ctx) {
                      return AlertDialog(
                        title: Text(
                          'Restaurar',
                          style: TextStyle(fontSize: size.width * 0.065),
                          textAlign: TextAlign.center,
                        ),
                        actions: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  // Tela de Carregamento.
                                  LoadScreen().loadingScreen(context);

                                  // Explicação se encontra na Função.
                                  await Database()
                                      .updateDataBase()
                                      .get()
                                      .then((value) {
                                    databaseBackup = value.value!;
                                  });

                                  // Explicação se encontra na Função.
                                  await storage
                                      .delete('list')
                                      .then((value) async {
                                    try {
                                      // Explicação se encontra na Função.
                                      await ControleArquivo().writeAdd(
                                          'list', databaseBackup['Lista']);

                                      // Explicação se encontra na Função.
                                      await ControleArquivo()
                                          .readCounter('list')
                                          .then((value) {
                                        widget.group.list = value;
                                      });

                                      // Explicação se encontra na Função.
                                      await getNameFromSpotify(
                                              widget.group.get('list'), {})
                                          .then((value) {
                                        widget.group.listMap = value;

                                        setState(() {});
                                      });
                                    } catch (error) {
                                      // caso não encontre a playlist volta para o textField.
                                    }
                                  });

                                  if (context.mounted) {
                                    // Remove a tela que está no topo.
                                    Navigator.of(context).pop();
                                    // Remove a tela que está no topo.
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text(
                                  'Lista',
                                  style: TextStyle(fontSize: size.width * 0.07),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  // Tela de Carregamento.
                                  LoadScreen().loadingScreen(context);

                                  // Explicação se encontra na Função.
                                  await Database()
                                      .updateDataBase()
                                      .get()
                                      .then((value) {
                                    databaseBackup = value.value!;
                                  });

                                  // Explicação se encontra na Função.
                                  await storage
                                      .delete('mixes')
                                      .then((value) async {
                                    try {
                                      // Explicação se encontra na Função.
                                      await ControleArquivo().writeAdd(
                                          'mixes', databaseBackup['Mixes']);

                                      // Explicação se encontra na Função.
                                      await ControleArquivo()
                                          .readCounter('mixes')
                                          .then((value) {
                                        widget.group.mixes = value;
                                      });

                                      // Explicação se encontra na Função.
                                      await getNameFromSpotify(
                                              widget.group.get('mixes'), {})
                                          .then((value) {
                                        widget.group.mixesMap = value;

                                        setState(() {});
                                      });
                                    } catch (error) {
                                      // caso não encontre a playlist volta para o textField.
                                    }
                                  });

                                  if (context.mounted) {
                                    // Remove a tela que está no topo.
                                    Navigator.of(context).pop();
                                    // Remove a tela que está no topo.
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text(
                                  'Mixes',
                                  style: TextStyle(fontSize: size.width * 0.07),
                                ),
                              )
                            ],
                          ),
                        ],
                      );
                    });
              },
              child: Icon(
                Icons.restore,
                color: Colors.white,
                size: size.width * 0.08,
              ))
        ],
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Texto invisível para fixar o texto principal no meio.
                const Text(
                  'aaa',
                  style: TextStyle(color: Colors.transparent),
                ),
                // Texto Principal.
                Text(
                  'Lista',
                  style: TextStyle(
                    fontSize: size.width * 0.06,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
                // TextButton de + para adicionar conteúdo na Lista.
                TextButton(
                  onPressed: () {
                    // faz o input aparecer e verificar se existe o link
                    add(size, 'list');
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(size.width * 0.01, size.height * 0.005),
                  ),
                  child: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          // Retângulo com nomes das Listas.
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
            ),
            child: SingleChildScrollView(
              child: SizedBox(
                width: size.width * 0.80,
                height: size.height * 0.37,
                child: ListView.builder(
                    itemCount: widget.group.listMap.length,
                    itemBuilder: (ctx, index) {
                      return rowText('list', size, index);
                    }),
              ),
            ),
          ),
          // Dar um espaço entre os Widget's.
          SizedBox(height: size.height * 0.005),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Texto invisível para fixar o texto principal no meio.
                const Text(
                  'aaa',
                  style: TextStyle(color: Colors.transparent),
                ),
                // Texto Principal.
                Text(
                  'Mixes',
                  style: TextStyle(
                    fontSize: size.width * 0.06,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
                // TextButton de + para adicionar conteúdo no Mixes.
                TextButton(
                  onPressed: () {
                    // faz o input aparecer e verificar se existe o link
                    add(size, 'mixes');
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(size.width * 0.01, size.height * 0.005),
                  ),
                  child: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          // Retângulo com nomes dos Mixes.
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
            ),
            child: SingleChildScrollView(
              child: SizedBox(
                  width: size.width * 0.80,
                  height: size.height * 0.37,
                  child: ListView.builder(
                      itemCount: widget.group.mixesMap.length,
                      itemBuilder: (ctx, index) {
                        return rowText('mixes', size, index);
                      })),
            ),
          ),
        ]),
      ),
    );
  }
}
