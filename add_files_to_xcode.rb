#!/usr/bin/env ruby
# encoding: utf-8
# 安全地添加文件到 Xcode 项目

require 'securerandom'

def generate_xcode_id
  # 生成 24 字符的十六进制 ID
  SecureRandom.hex(12).upcase
end

# 读取项目文件
project_file = 'Moyu.xcodeproj/project.pbxproj'
content = File.read(project_file, encoding: 'UTF-8')

# 定义要添加的文件
files = [
  { name: 'ColorTheme.swift', group: 'Utils', group_id: '306' },
  { name: 'ViewModifiers.swift', group: 'Utils', group_id: '306' },
  { name: 'SafeSQLBuilder.swift', group: 'Utils', group_id: '306' },
  { name: 'PracticeSessionView.swift', group: 'Views', group_id: '304' },
  { name: 'EnhancedStatisticsView.swift', group: 'Views', group_id: '304' },
  { name: 'SpacedRepetitionService.swift', group: 'Services', group_id: '305' }
]

# 检查文件是否已存在
files.reject! { |f| content.include?(f[:name]) }

if files.empty?
  puts "✅ 所有文件都已存在"
  exit 0
end

puts "准备添加 #{files.size} 个文件..."

# 为每个文件生成 ID
files.each do |file|
  file[:file_ref_id] = generate_xcode_id
  file[:build_file_id] = generate_xcode_id
end

# 1. 添加 PBXBuildFile 条目
build_file_section_start = content.index('/* Begin PBXBuildFile section */')
if build_file_section_start
  # 找到第一个现有条目的位置
  first_entry_pos = content.index("\t\t0", build_file_section_start)

  build_entries = files.map do |f|
    "\t\t#{f[:build_file_id]} /* #{f[:name]} in Sources */ = {isa = PBXBuildFile; fileRef = #{f[:file_ref_id]} /* #{f[:name]} */; };"
  end.join("\n")

  content.insert(first_entry_pos, build_entries + "\n")
  puts "✅ 添加了 PBXBuildFile 条目"
end

# 2. 添加 PBXFileReference 条目
file_ref_section_start = content.index('/* Begin PBXFileReference section */')
if file_ref_section_start
  first_entry_pos = content.index("\t\t1", file_ref_section_start)

  file_ref_entries = files.map do |f|
    "\t\t#{f[:file_ref_id]} /* #{f[:name]} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = #{f[:name]}; sourceTree = \"<group>\"; };"
  end.join("\n")

  content.insert(first_entry_pos, file_ref_entries + "\n")
  puts "✅ 添加了 PBXFileReference 条目"
end

# 3. 添加到 Sources 构建阶段
sources_phase = content.match(/\/\* Sources \*\/ = \{[^}]+files = \(\s*/)
if sources_phase
  insert_pos = sources_phase.end(0)

  source_entries = files.map do |f|
    "\t\t\t\t#{f[:build_file_id]} /* #{f[:name]} in Sources */,"
  end.join("\n")

  content.insert(insert_pos, source_entries + "\n")
  puts "✅ 添加到 Sources 构建阶段"
end

# 4. 添加到相应的组
files.group_by { |f| f[:group_id] }.each do |group_id, group_files|
  # 查找组定义
  group_pattern = /#{group_id} \/\* \w+ \*\/ = \{\s+isa = PBXGroup;\s+children = \(\s*/
  group_match = content.match(group_pattern)

  if group_match
    insert_pos = group_match.end(0)

    group_entries = group_files.map do |f|
      "\t\t\t\t#{f[:file_ref_id]} /* #{f[:name]} */,"
    end.join("\n")

    content.insert(insert_pos, group_entries + "\n")
    puts "✅ 添加到 #{group_files.first[:group]} 组"
  end
end

# 写回文件
File.write(project_file, content)

puts "\n🎉 成功添加了 #{files.size} 个文件！"
files.each do |f|
  puts "   ✓ #{f[:name]}"
end
