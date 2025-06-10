import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final IconData? iconData; // NOVO: Parâmetro opcional para o ícone de fallback.

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
    this.iconData, // NOVO: Adicionado ao construtor.
  });

  // Função para gerar uma cor com base no nome
  Color _colorFromName(String name) {
    final hash = name.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = hash & 0x0000FF;
    return Color.fromRGBO(r, g, b, 0.5); // 50% de opacidade para um tom mais suave
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: hasImage ? Colors.transparent : _colorFromName(name),
      // Se tiver imagem, usa a imagem da rede.
      backgroundImage: hasImage ? CachedNetworkImageProvider(imageUrl!) : null,
      // Se NÃO tiver imagem, usa o fallback.
      child: !hasImage
      // CORREÇÃO: Verifica se um iconData foi fornecido, senão usa a inicial do nome.
          ? (iconData != null
          ? Icon(iconData, size: radius * 1.1, color: Colors.white.withOpacity(0.8))
          : Text(
        name.isNotEmpty ? name[0].toUpperCase() : '',
        style: TextStyle(
          fontSize: radius * 0.9,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ))
          : null,
    );
  }
}