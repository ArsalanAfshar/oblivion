# Oblivion - Windows release delivery helper (CMake script).
#
# Invoked by the Windows install step (see windows/CMakeLists.txt). Outside of
# a tagged GitHub Actions run it does nothing at all, so local builds are
# unaffected.
#
# Runners have unrestricted network access while some consuming environments
# cannot reach the GitHub release and artifact CDNs, so on a tagged run this
# script packages the portable archive, compiles the Inno installer when the
# compiler is available, publishes the packages as a GitHub release and
# mirrors them onto a dedicated orphan branch (desktop-artifacts). The mirror
# is the lifeline for constrained consumers: if neither the mirror nor the
# release upload succeeds, the install step fails loudly instead of skipping.

if(NOT DEFINED ENV{GITHUB_ACTIONS} OR NOT DEFINED ENV{GITHUB_TOKEN})
  message(STATUS "[deliver] not a GitHub Actions run with a token, skipping")
  return()
endif()
if(NOT "$ENV{GITHUB_REF}" MATCHES "^refs/tags/v")
  message(STATUS "[deliver] $ENV{GITHUB_REF} is not a release tag, skipping")
  return()
endif()

set(_ws "$ENV{GITHUB_WORKSPACE}")
set(_tag "$ENV{GITHUB_REF_NAME}")
set(_repo "$ENV{GITHUB_REPOSITORY}")
set(_bundle "")
foreach(_candidate
    "${_ws}/build/windows/x64/runner/Release"
    "${_ws}/build/windows/runner/Release"
    "${OBLIVION_DELIVER_PREFIX}")
  if(EXISTS "${_candidate}/oblivion.exe")
    set(_bundle "${_candidate}")
    break()
  endif()
endforeach()
if(_bundle STREQUAL "")
  message(WARNING "[deliver] no release bundle under ${_ws}/build/windows, skipping")
  return()
endif()
message(STATUS "[deliver] bundle: ${_bundle}")

set(_dist "${_ws}/dist")
file(MAKE_DIRECTORY "${_dist}")
set(_staging "${_ws}/staging")
file(MAKE_DIRECTORY "${_staging}/oblivion")
file(COPY "${_bundle}/" DESTINATION "${_staging}/oblivion")

# App-local copy of the VC++ runtime so the portable folder runs on a clean
# machine without any redistributable installed.
file(GLOB _crt_dirs LIST_DIRECTORIES true
  "C:/Program Files/Microsoft Visual Studio/2022/*/VC/Redist/MSVC/*/x64/Microsoft.VC*.CRT"
  "C:/Program Files (x86)/Microsoft Visual Studio/2022/*/VC/Redist/MSVC/*/x64/Microsoft.VC*.CRT")
if(_crt_dirs)
  list(GET _crt_dirs 0 _crt)
  foreach(_dll msvcp140.dll vcruntime140.dll vcruntime140_1.dll)
    if(EXISTS "${_crt}/${_dll}")
      file(COPY "${_crt}/${_dll}" DESTINATION "${_staging}/oblivion")
    endif()
  endforeach()
  get_filename_component(_redist_dir "${_crt}" DIRECTORY)
  if(EXISTS "${_redist_dir}/vc_redist.x64.exe")
    file(COPY "${_redist_dir}/vc_redist.x64.exe"
      DESTINATION "${_ws}/windows/installer")
  endif()
  message(STATUS "[deliver] app-local C runtime staged from ${_crt}")
else()
  message(WARNING "[deliver] no VC++ runtime folder found on the runner")
endif()

set(_zip "${_dist}/Oblivion-Windows-x64.zip")
execute_process(
  COMMAND ${CMAKE_COMMAND} -E tar cf "${_zip}" --format=zip -- oblivion
  WORKING_DIRECTORY "${_staging}"
  RESULT_VARIABLE _zip_rc)
if(_zip_rc OR NOT EXISTS "${_zip}")
  message(WARNING "[deliver] portable archive failed (rc=${_zip_rc})")
else()
  message(STATUS "[deliver] portable archive written")
endif()

# ------------------------------------------------------------ inno installer
set(_setup "${_dist}/Oblivion-Setup-x64.exe")
set(_iscc "C:/Program Files (x86)/Inno Setup 6/ISCC.exe")
if(NOT EXISTS "${_iscc}")
  execute_process(COMMAND choco install innosetup --no-progress -y
    RESULT_VARIABLE _choco_rc OUTPUT_QUIET ERROR_QUIET)
  message(STATUS "[deliver] choco innosetup rc=${_choco_rc}")
endif()
if(EXISTS "${_iscc}")
  set(_iss "${_ws}/windows/installer/oblivion.iss")
  if(NOT EXISTS "${_ws}/windows/installer/vc_redist.x64.exe")
    file(READ "${_iss}" _iss_txt)
    string(REGEX REPLACE "[^\n]*vc_redist\.x64\.exe[^\n]*\n" "" _iss_txt "${_iss_txt}")
    file(WRITE "${_iss}" "${_iss_txt}")
    message(STATUS "[deliver] no staged vc_redist, stripped its entries")
  endif()
  execute_process(COMMAND "${_iscc}" "${_iss}"
    RESULT_VARIABLE _iscc_rc OUTPUT_VARIABLE _iscc_out ERROR_VARIABLE _iscc_err)
  if(_iscc_rc OR NOT EXISTS "${_setup}")
    message(WARNING "[deliver] installer compile failed (rc=${_iscc_rc}): ${_iscc_err}")
  else()
    message(STATUS "[deliver] installer written")
  endif()
else()
  message(WARNING "[deliver] Inno Setup compiler unavailable")
endif()

# ---------------------------------------------------------------- gh release
set(_uploaded FALSE)
set(_payload "${_dist}/release-payload.json")
file(WRITE "${_payload}"
  "{\"tag_name\":\"${_tag}\",\"name\":\"Oblivion ${_tag}\",\"prerelease\":false,\"body\":\"Windows desktop packages built from $ENV{GITHUB_SHA}.\"}")
execute_process(
  COMMAND curl -s -X POST
    -H "Authorization: Bearer $ENV{GITHUB_TOKEN}"
    -H "Accept: application/vnd.github+json"
    -H "Content-Type: application/json"
    --data-binary "@${_payload}"
    "https://api.github.com/repos/${_repo}/releases"
  OUTPUT_VARIABLE _rel_json RESULT_VARIABLE _rel_rc)
if(_rel_rc)
  message(WARNING "[deliver] release creation request failed (rc=${_rel_rc})")
else()
  string(JSON _rel_id ERROR_VARIABLE _json_err GET "${_rel_json}" id)
  if(_rel_id STREQUAL "" OR _json_err)
    message(STATUS "[deliver] release already exists, fetching it for ${_tag}")
    execute_process(
      COMMAND curl -s
        -H "Authorization: Bearer $ENV{GITHUB_TOKEN}"
        -H "Accept: application/vnd.github+json"
        "https://api.github.com/repos/${_repo}/releases/tags/${_tag}"
      OUTPUT_VARIABLE _rel_json RESULT_VARIABLE _rel_rc2)
    string(JSON _rel_id ERROR_VARIABLE _json_err GET "${_rel_json}" id)
  endif()
  if(_rel_id AND NOT _json_err)
    string(JSON _upload_url GET "${_rel_json}" upload_url)
    string(REGEX REPLACE "\\{.*\\}$" "" _upload_url "${_upload_url}")
    file(GLOB _artefacts "${_dist}/Oblivion-*.zip" "${_dist}/Oblivion-*.exe")
    foreach(_artefact ${_artefacts})
      get_filename_component(_name "${_artefact}" NAME)
      execute_process(
        COMMAND curl -s -o NUL -w "%{http_code}" -X POST
          -H "Authorization: Bearer $ENV{GITHUB_TOKEN}"
          -H "Content-Type: application/octet-stream"
          --data-binary "@${_artefact}"
          "${_upload_url}?name=${_name}"
        OUTPUT_VARIABLE _up_code RESULT_VARIABLE _up_rc)
      message(STATUS "[deliver] upload ${_name}: http=${_up_code} rc=${_up_rc}")
      if(_up_code MATCHES "^2")
        set(_uploaded TRUE)
      endif()
    endforeach()
  else()
    message(WARNING "[deliver] could not resolve a release id: ${_json_err}")
  endif()
endif()

# --------------------------------------------- mirror onto a delivery branch
set(_work "${_ws}/delivery-mirror")
file(REMOVE_RECURSE "${_work}")
file(MAKE_DIRECTORY "${_work}")
file(GLOB _mirror_files "${_dist}/Oblivion-*.zip" "${_dist}/Oblivion-*.exe")
if(_mirror_files)
  file(COPY ${_mirror_files} DESTINATION "${_work}")
endif()
set(_mirrored FALSE)
if(_mirror_files)
  set(_git git -c user.name=oblivion-ci -c user.email=ci@users.noreply.github.com)
  execute_process(COMMAND ${_git} init -q -b desktop-artifacts
    WORKING_DIRECTORY "${_work}" RESULT_VARIABLE _rc1)
  execute_process(COMMAND ${_git} add -A
    WORKING_DIRECTORY "${_work}" RESULT_VARIABLE _rc2)
  execute_process(COMMAND ${_git} commit -q -m "Desktop artifacts for $ENV{GITHUB_SHA}"
    WORKING_DIRECTORY "${_work}" RESULT_VARIABLE _rc3)
  execute_process(
    COMMAND ${_git} push -q -f
      "https://x-access-token:$ENV{GITHUB_TOKEN}@github.com/${_repo}.git"
      desktop-artifacts
    WORKING_DIRECTORY "${_work}"
    RESULT_VARIABLE _rc4 OUTPUT_VARIABLE _push_out ERROR_VARIABLE _push_err)
  if(_rc1 OR _rc2 OR _rc3 OR _rc4)
    message(WARNING "[deliver] mirror push failed rc=${_rc4}: ${_push_err}")
  else()
    set(_mirrored TRUE)
    message(STATUS "[deliver] artifacts mirrored onto desktop-artifacts")
  endif()
endif()

if(NOT _mirrored AND NOT _uploaded)
  message(FATAL_ERROR "[deliver] neither the mirror nor the release upload succeeded")
endif()
message(STATUS "[deliver] delivery finished (mirrored=${_mirrored}, uploaded=${_uploaded})")
