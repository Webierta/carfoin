import 'package:flutter/material.dart';

//import 'menus.dart';

enum Menu { ordenar, exportar, eliminar }

enum MenuCartera { ordenar, eliminar }

enum MenuFondo { mercado, eliminar, exportar }

PopupMenuItem<Enum> buildMenuItem(Enum menu, IconData iconData,
    {bool divider = false, bool isOrder = false}) {
  return PopupMenuItem(
    value: menu,
    child: Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 2),
          dense: true,
          leading: Icon(iconData, color: const Color(0xFFFFFFFF)),
          title: Text(
            '${menu.name[0].toUpperCase()}${menu.name.substring(1)}',
            style: const TextStyle(color: Color(0xFFFFFFFF)),
            maxLines: 1,
          ),
          trailing: menu == Menu.ordenar || menu == MenuCartera.ordenar
              ? Icon(
                  isOrder ? Icons.check_box : Icons.check_box_outline_blank,
                  color: const Color(0xFFFFFFFF),
                )
              : null,
        ),
        if (divider == true) const Divider(color: Color(0xFFFFFFFF)), // PopMenuDivider
      ],
    ),
  );
}

/* PAGE HOME
PopupMenuItem<Menu> _buildMenuItem(Menu menu, IconData iconData, {bool divider = false}) {
    return PopupMenuItem(
      value: menu,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 2),
            dense: true,
            leading: Icon(iconData, color: const Color(0xFFFFFFFF)),
            title: Text(
              '${menu.name[0].toUpperCase()}${menu.name.substring(1)}',
              style: const TextStyle(color: Color(0xFFFFFFFF)),
              maxLines: 1,
            ),
            trailing: menu == Menu.ordenar
                ? Icon(
                    _isCarterasByOrder ? Icons.check_box : Icons.check_box_outline_blank,
                    color: const Color(0xFFFFFFFF),
                  )
                : null,
          ),
          if (divider == true) const Divider(color: Color(0xFFFFFFFF)), // PopMenuDivider
        ],
      ),
    );
  }*/

/* PAGE CARTERA
PopupMenuItem<MenuCartera> _buildMenuItem(MenuCartera menu, IconData iconData,
      {bool divider = false}) {
    return PopupMenuItem(
      value: menu,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 2),
            dense: true,
            leading: Icon(iconData, color: const Color(0xFFFFFFFF)),
            title: Text(
              '${menu.name[0].toUpperCase()}${menu.name.substring(1)}',
              style: const TextStyle(color: Color(0xFFFFFFFF)),
              maxLines: 1,
            ),
            trailing: menu == MenuCartera.ordenar
                ? Icon(
                    _isFondosByOrder ? Icons.check_box : Icons.check_box_outline_blank,
                    color: const Color(0xFFFFFFFF),
                  )
                : null,
          ),
          if (divider) const Divider(height: 10, color: Color(0xFFFFFFFF)), // PopMenuDivider
        ],
      ),
    );
  }*/

/* PAGE FONDO
PopupMenuItem<MenuFondo> _buildMenuItem(MenuFondo menu, IconData iconData,
      {bool divider = false}) {
    return PopupMenuItem(
      value: menu,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 2),
            dense: true,
            leading: Icon(iconData, color: const Color(0xFFFFFFFF)),
            title: Text(
              '${menu.name[0].toUpperCase()}${menu.name.substring(1)}',
              style: const TextStyle(color: Color(0xFFFFFFFF)),
              maxLines: 1,
            ),
          ),
          if (divider) const Divider(color: Color(0xFFFFFFFF)), // PopMenuDivider
        ],
      ),
    );
  }*/
