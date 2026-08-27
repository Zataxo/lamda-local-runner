class Project {
  final String id;
  final String name;
  final String? repoUrl;
  final String localPath;
  String? lastBranch;
  String? artifactsPath;

  Project({
    required this.id,
    required this.name,
    required this.localPath,
    this.repoUrl,
    this.lastBranch,
    this.artifactsPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'repoUrl': repoUrl,
        'localPath': localPath,
        'lastBranch': lastBranch,
        'artifactsPath': artifactsPath,
      };

  factory Project.fromJson(Map<String, dynamic> j) => Project(
        id: j['id'] as String,
        name: j['name'] as String,
        localPath: j['localPath'] as String,
        repoUrl: j['repoUrl'] as String?,
        lastBranch: j['lastBranch'] as String?,
        artifactsPath: j['artifactsPath'] as String?,
      );
}
