#!/usr/bin/env python3
"""
自动将新的 Swift 文件添加到 Xcode 项目中
"""
import re
import uuid

def generate_xcode_id():
    """生成 Xcode 使用的 24 字符 ID"""
    return uuid.uuid4().hex[:24].upper()

def add_files_to_xcode_project(project_path):
    """添加文件到 Xcode 项目"""

    # 读取项目文件
    with open(project_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 要添加的文件
    files_to_add = [
        {
            'name': 'ColorTheme.swift',
            'path': 'Moyu/Utils/ColorTheme.swift',
            'group': 'Utils'
        },
        {
            'name': 'ViewModifiers.swift',
            'path': 'Moyu/Utils/ViewModifiers.swift',
            'group': 'Utils'
        },
        {
            'name': 'SafeSQLBuilder.swift',
            'path': 'Moyu/Utils/SafeSQLBuilder.swift',
            'group': 'Utils'
        },
        {
            'name': 'PracticeSessionView.swift',
            'path': 'Moyu/Views/PracticeSessionView.swift',
            'group': 'Views'
        },
        {
            'name': 'EnhancedStatisticsView.swift',
            'path': 'Moyu/Views/EnhancedStatisticsView.swift',
            'group': 'Views'
        },
        {
            'name': 'SpacedRepetitionService.swift',
            'path': 'Moyu/Services/SpacedRepetitionService.swift',
            'group': 'Services'
        }
    ]

    # 检查文件是否已存在
    existing_files = []
    for file_info in files_to_add:
        if file_info['name'] in content:
            existing_files.append(file_info['name'])
            print(f"⚠️  文件已存在: {file_info['name']}")

    # 过滤掉已存在的文件
    files_to_add = [f for f in files_to_add if f['name'] not in existing_files]

    if not files_to_add:
        print("✅ 所有文件都已存在于项目中")
        return

    # 生成新的 ID
    file_refs = {}
    build_files = {}

    for file_info in files_to_add:
        file_refs[file_info['name']] = generate_xcode_id()
        build_files[file_info['name']] = generate_xcode_id()

    # 1. 添加到 PBXBuildFile section
    build_file_section = '/* Begin PBXBuildFile section */'
    build_file_idx = content.find(build_file_section)

    if build_file_idx != -1:
        # 找到下一行的位置
        next_line_idx = content.find('\n', build_file_idx) + 1

        # 生成 PBXBuildFile 条目
        build_file_entries = []
        for file_info in files_to_add:
            name = file_info['name']
            entry = f"\t\t{build_files[name]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[name]} /* {name} */; }};\n"
            build_file_entries.append(entry)

        content = content[:next_line_idx] + ''.join(build_file_entries) + content[next_line_idx:]
        print(f"✅ 添加了 {len(build_file_entries)} 个 PBXBuildFile 条目")

    # 2. 添加到 PBXFileReference section
    file_ref_section = '/* Begin PBXFileReference section */'
    file_ref_idx = content.find(file_ref_section)

    if file_ref_idx != -1:
        next_line_idx = content.find('\n', file_ref_idx) + 1

        # 生成 PBXFileReference 条目
        file_ref_entries = []
        for file_info in files_to_add:
            name = file_info['name']
            entry = f"\t\t{file_refs[name]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};\n"
            file_ref_entries.append(entry)

        content = content[:next_line_idx] + ''.join(file_ref_entries) + content[next_line_idx:]
        print(f"✅ 添加了 {len(file_ref_entries)} 个 PBXFileReference 条目")

    # 3. 添加到 PBXSourcesBuildPhase (Sources)
    sources_section_pattern = r'(/\* Sources \*/.*?isa = PBXSourcesBuildPhase;.*?files = \()'
    sources_match = re.search(sources_section_pattern, content, re.DOTALL)

    if sources_match:
        insert_pos = sources_match.end()

        # 生成 Sources 条目
        source_entries = []
        for file_info in files_to_add:
            name = file_info['name']
            entry = f"\n\t\t\t\t{build_files[name]} /* {name} in Sources */,"
            source_entries.append(entry)

        content = content[:insert_pos] + ''.join(source_entries) + content[insert_pos:]
        print(f"✅ 添加了 {len(source_entries)} 个文件到 Sources 构建阶段")

    # 4. 添加文件到相应的组 (Utils/Views/Services)
    # 需要更精确地查找组，避免匹配到错误的位置

    # 先找到所有组的定义
    group_sections = {
        'Utils': None,
        'Views': None,
        'Services': None
    }

    # 查找每个组的位置
    for group_name in group_sections.keys():
        # 更精确的模式：找到 306 /* Utils */ 这样的定义
        pattern = rf'(\d+) /\* {group_name} \*/ = {{\s+isa = PBXGroup;\s+children = \('
        match = re.search(pattern, content, re.DOTALL)
        if match:
            group_sections[group_name] = match

    for group_name, match in group_sections.items():
        if not match:
            print(f"⚠️  找不到 {group_name} 组")
            continue

        insert_pos = match.end()

        # 过滤属于这个组的文件
        group_files = [f for f in files_to_add if f['group'] == group_name]

        if group_files:
            group_entries = []
            for file_info in group_files:
                name = file_info['name']
                entry = f"\n\t\t\t\t{file_refs[name]} /* {name} */,"
                group_entries.append(entry)

            content = content[:insert_pos] + ''.join(group_entries) + content[insert_pos:]
            print(f"✅ 添加了 {len(group_entries)} 个文件到 {group_name} 组")

    # 写回文件
    with open(project_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"\n🎉 成功添加了 {len(files_to_add)} 个文件到 Xcode 项目！")
    for file_info in files_to_add:
        print(f"   ✓ {file_info['path']}")

if __name__ == '__main__':
    project_path = 'Moyu.xcodeproj/project.pbxproj'
    print("开始添加文件到 Xcode 项目...\n")
    add_files_to_xcode_project(project_path)
    print("\n✅ 完成！")
