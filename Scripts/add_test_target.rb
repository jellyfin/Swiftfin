#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Adds the SwiftfinTests (iOS) and SwiftfinTVOSTests (tvOS) unit-test
# bundles to Swiftfin.xcodeproj and wires them into the matching shared
# schemes. Idempotent: safe to re-run on an already-scaffolded project.
# Run from the repo root: `ruby Scripts/add_test_target.rb`.

require "xcodeproj"

PROJECT_PATH = "Swiftfin.xcodeproj"

TARGETS = [
  {
    name: "SwiftfinTests",
    host: "Swiftfin iOS",
    sdk_root: :ios,
    sources_dir: "Tests/SwiftfinTests",
    bundle_id: "org.jellyfin.swiftfin.tests",
    scheme_name: "Swiftfin",
    deployment_setting: "IPHONEOS_DEPLOYMENT_TARGET",
    default_deployment: "16.6",
    targeted_device_family: "1,2",
    test_host_app: "Swiftfin iOS",
  },
  {
    name: "SwiftfinTVOSTests",
    host: "Swiftfin tvOS",
    sdk_root: :tvos,
    sources_dir: "Tests/SwiftfinTVOSTests",
    bundle_id: "org.jellyfin.swiftfin.tvos.tests",
    scheme_name: "Swiftfin tvOS",
    deployment_setting: "TVOS_DEPLOYMENT_TARGET",
    default_deployment: "16.6",
    targeted_device_family: "3",
    test_host_app: "Swiftfin tvOS",
  },
].freeze

project = Xcodeproj::Project.open(PROJECT_PATH)

def find_swift_files(dir)
  return [] unless Dir.exist?(dir)
  Dir.glob(File.join(dir, "**", "*.swift")).sort
end

def ensure_group(project, path_components)
  parent = project.main_group
  path_components.each do |component|
    sub = parent.children.find { |c| c.respond_to?(:path) && c.path == component }
    if sub.nil?
      sub = parent.new_group(component, component)
      sub.set_source_tree("<group>")
    end
    parent = sub
  end
  parent
end

TARGETS.each do |spec|
  if project.targets.any? { |t| t.name == spec[:name] }
    puts "[add_test_target] '#{spec[:name]}' already exists — skipping."
    next
  end

  host_target = project.targets.find { |t| t.name == spec[:host] }
  abort "Host target '#{spec[:host]}' not found" unless host_target

  host_debug = host_target.build_configurations.find { |c| c.name == "Debug" }
  deployment_target = host_debug.build_settings[spec[:deployment_setting]] || spec[:default_deployment]
  swift_version     = host_debug.build_settings["SWIFT_VERSION"] || "5.0"

  test_target = project.new_target(
    :unit_test_bundle,
    spec[:name],
    spec[:sdk_root],
    deployment_target,
    project.products_group,
    :swift,
  )

  test_host = "$(BUILT_PRODUCTS_DIR)/#{spec[:test_host_app]}.app/#{spec[:test_host_app]}"
  test_target.build_configurations.each do |cfg|
    s = cfg.build_settings
    s["PRODUCT_NAME"]                = "$(TARGET_NAME)"
    s[spec[:deployment_setting]]     = deployment_target
    s["SWIFT_VERSION"]               = swift_version
    s["PRODUCT_BUNDLE_IDENTIFIER"]   = spec[:bundle_id]
    s["GENERATE_INFOPLIST_FILE"]     = "YES"
    s["TEST_HOST"]                   = test_host
    s["BUNDLE_LOADER"]               = "$(TEST_HOST)"
    s["CODE_SIGN_STYLE"]             = "Automatic"
    s["TARGETED_DEVICE_FAMILY"]      = spec[:targeted_device_family]
    s["LD_RUNPATH_SEARCH_PATHS"]     = [
      "$(inherited)",
      "@executable_path/Frameworks",
      "@loader_path/Frameworks",
    ]
  end

  group_components = spec[:sources_dir].split(File::SEPARATOR)
  group = ensure_group(project, group_components)

  swift_files = find_swift_files(spec[:sources_dir])
  swift_files.each do |path|
    rel = File.basename(path)
    file_ref = group.files.find { |f| f.path == rel } || group.new_reference(rel)
    test_target.source_build_phase.add_file_reference(file_ref, true)
  end

  test_target.add_dependency(host_target)

  puts "[add_test_target] Added '#{spec[:name]}' (host: #{spec[:host]}, deployment: #{deployment_target}, swift: #{swift_version}, sources: #{swift_files.size})."
end

project.save

# Wire each test target into its host scheme.
TARGETS.each do |spec|
  test_target = project.targets.find { |t| t.name == spec[:name] }
  next unless test_target

  scheme_path = File.join(PROJECT_PATH, "xcshareddata/xcschemes/#{spec[:scheme_name]}.xcscheme")
  unless File.exist?(scheme_path)
    warn "[add_test_target] Scheme not found, skipping wire-up: #{scheme_path}"
    next
  end

  scheme = Xcodeproj::XCScheme.new(scheme_path)

  already_in_build = scheme.build_action.entries.any? { |e|
    e.buildable_references.any? { |r| r.target_name == spec[:name] }
  }
  unless already_in_build
    build_entry = Xcodeproj::XCScheme::BuildAction::Entry.new(test_target)
    build_entry.build_for_testing   = true
    build_entry.build_for_running   = false
    build_entry.build_for_profiling = false
    build_entry.build_for_archiving = false
    build_entry.build_for_analyzing = false
    scheme.build_action.add_entry(build_entry)
  end

  already_testable = scheme.test_action.testables.any? { |t|
    t.buildable_references.any? { |r| r.target_name == spec[:name] }
  }
  unless already_testable
    testable = Xcodeproj::XCScheme::TestAction::TestableReference.new(test_target)
    scheme.test_action.add_testable(testable)
  end

  scheme.save!
  puts "[add_test_target] Wired '#{spec[:name]}' into scheme: #{scheme_path}"
end
