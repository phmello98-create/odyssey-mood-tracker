"""
Project Structure Resource
Fornece informações sobre a estrutura do projeto
"""

from pathlib import Path
from typing import Any


class ProjectStructureResource:
    """Recurso de estrutura do projeto"""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.lib_path = project_root / "lib"
    
    def get_structure_markdown(self) -> str:
        """Retorna estrutura do projeto em Markdown"""
        output = ["# Odyssey Mood Tracker - Project Structure\n"]
        
        if not self.lib_path.exists():
            return "Error: lib directory not found"
        
        output.append("## Directory Structure\n")
        output.append("```")
        output.append(self._generate_tree(self.lib_path, prefix=""))
        output.append("```\n")
        
        # Features
        features = self.list_features()
        if features.get("features"):
            output.append("\n## Features\n")
            for feature in features["features"]:
                output.append(f"### {feature['name']}")
                output.append(f"- **Path**: `{feature['path']}`")
                output.append(f"- **Files**: {feature['file_count']}")
                if feature.get('screens'):
                    output.append(f"- **Screens**: {', '.join(feature['screens'])}")
                output.append("")
        
        return "\n".join(output)
    
    def _generate_tree(self, directory: Path, prefix: str = "", max_depth: int = 3, current_depth: int = 0) -> str:
        """Gera árvore de diretórios"""
        if current_depth >= max_depth:
            return ""
        
        output = []
        try:
            items = sorted(directory.iterdir(), key=lambda x: (not x.is_dir(), x.name))
            
            for i, item in enumerate(items):
                is_last = i == len(items) - 1
                current_prefix = "└── " if is_last else "├── "
                next_prefix = "    " if is_last else "│   "
                
                if item.is_dir():
                    # Skip alguns diretórios
                    if item.name.startswith('.') or item.name in ['build', 'generated']:
                        continue
                    output.append(f"{prefix}{current_prefix}{item.name}/")
                    subtree = self._generate_tree(
                        item, 
                        prefix + next_prefix, 
                        max_depth, 
                        current_depth + 1
                    )
                    if subtree:
                        output.append(subtree)
                else:
                    if item.suffix in ['.dart', '.yaml', '.md']:
                        output.append(f"{prefix}{current_prefix}{item.name}")
        except PermissionError:
            pass
        
        return "\n".join(output)
    
    def list_features(self) -> dict[str, Any]:
        """Lista features do projeto"""
        features_path = self.lib_path / "src" / "features"
        
        if not features_path.exists():
            return {"features": [], "count": 0}
        
        features = []
        
        for feature_dir in features_path.iterdir():
            if not feature_dir.is_dir() or feature_dir.name.startswith('.'):
                continue
            
            # Conta arquivos
            dart_files = list(feature_dir.rglob("*.dart"))
            
            # Encontra screens
            screens = []
            screen_path = feature_dir / "presentation" / "screens"
            if screen_path.exists():
                screens = [f.stem for f in screen_path.glob("*.dart")]
            
            features.append({
                "name": feature_dir.name,
                "path": str(feature_dir.relative_to(self.project_root)),
                "file_count": len(dart_files),
                "screens": screens
            })
        
        return {
            "features": features,
            "count": len(features)
        }
    
    def get_feature_details(self, feature_name: str) -> str:
        """Retorna detalhes de uma feature"""
        features_path = self.lib_path / "src" / "features" / feature_name
        
        if not features_path.exists():
            return f"Feature '{feature_name}' not found"
        
        output = [f"# Feature: {feature_name}\n"]
        
        # Estrutura da feature
        output.append("## Structure\n")
        output.append("```")
        output.append(self._generate_tree(features_path, max_depth=2))
        output.append("```\n")
        
        # Screens
        screens_path = features_path / "presentation" / "screens"
        if screens_path.exists():
            screens = list(screens_path.glob("*.dart"))
            if screens:
                output.append("\n## Screens\n")
                for screen in screens:
                    output.append(f"- `{screen.name}`")
        
        # Widgets
        widgets_path = features_path / "presentation" / "widgets"
        if widgets_path.exists():
            widgets = list(widgets_path.glob("*.dart"))
            if widgets:
                output.append("\n## Widgets\n")
                for widget in widgets:
                    output.append(f"- `{widget.name}`")
        
        # Models
        models_path = features_path / "data" / "models"
        if models_path.exists():
            models = list(models_path.glob("*.dart"))
            if models:
                output.append("\n## Models\n")
                for model in models:
                    output.append(f"- `{model.name}`")
        
        return "\n".join(output)
