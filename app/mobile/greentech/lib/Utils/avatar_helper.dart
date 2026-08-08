class AvatarHelper {
  static const List<String> _avatarUrls = [
    'https://i.pinimg.com/736x/92/bf/e2/92bfe2947696cf8ae9f6f4d13b9d7fb1.jpg',
    'https://i.pinimg.com/736x/be/bd/22/bebd22047f6e0a2f0067928d9c7b1e3c.jpg',
    'https://i.pinimg.com/1200x/08/da/30/08da30a575506427b84a1595ee04e27a.jpg',
    'https://i.pinimg.com/1200x/1e/2a/3d/1e2a3d76a671c011740e3bc23ae9f085.jpg',
    'https://i.pinimg.com/736x/de/2b/c9/de2bc94d88e8661bb01834eb1a810aa1.jpg',
    'https://i.pinimg.com/736x/bd/a1/a4/bda1a430c0959cc629aa7cd97fdf29d8.jpg',
    'https://i.pinimg.com/1200x/74/48/83/7448839c766603ae48abeda10424e0fe.jpg',
    'https://i.pinimg.com/originals/df/59/6c/df596cf72bc8e3af16a522ae928ab6ea.gif',
    'https://i.pinimg.com/736x/69/32/27/693227b8a84b63cf5a9597f94c41f098.jpg',
  ];

  static String getAvatarForName(String name) {
    if (name.trim().isEmpty) return _avatarUrls[0];

    String firstLetter = name.trim()[0].toUpperCase();
    int charCode = firstLetter.codeUnitAt(0);

    if (charCode < 65 || charCode > 90) {
      return _avatarUrls[0];
    }

    int letterIndex = charCode - 65;
    int urlIndex = letterIndex % _avatarUrls.length;

    return _avatarUrls[urlIndex];
  }
}
