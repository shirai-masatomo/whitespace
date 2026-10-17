extends RefCounted
## Atomic single-slot storage. Reject malformed/new-version saves; never silently reset them.
const Expedition = preload("res://core/expedition.gd")
var path: String
var data: Dictionary
var cfg: Dictionary
var fingerprint := ""
var last_preserved_path := ""
var migration_pending := false
var migration_source := ""
var fault := "" # Test-only fault injection; never selected by the player UI.

func _init(save_path: String, combat_data: Dictionary, config: Dictionary) -> void:
	path=ProjectSettings.globalize_path(save_path)
	data=combat_data
	cfg=config
	fingerprint=digest()

func digest() -> String:
	return FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""

func read_one(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path): return {"ok":false,"status":"missing","error":"保存データはありません。"}
	var file := FileAccess.open(file_path,FileAccess.READ)
	if file==null: return {"ok":false,"status":"unreadable","error":"保存データを読み取れません。"}
	if file.get_length()>4000000: return {"ok":false,"status":"invalid","error":"保存データが大きすぎます。元ファイルを保持しました。"}
	var parser := JSON.new()
	if parser.parse(file.get_as_text())!=OK or not parser.data is Dictionary:
		return {"ok":false,"status":"invalid","error":"保存データが壊れています。元ファイルを保持しました。"}
	if parser.data.has("schema_version") and (parser.data.schema_version!=1 and parser.data.schema_version!=2):
		return {"ok":false,"status":"version","error":"未対応の保存形式です。古いバックアップへの自動巻戻しはしません。"}
	var saved_config: Dictionary=cfg
	if parser.data.get("config_version")!=cfg.config_version:
		saved_config=Expedition.load_config(str(parser.data.get("config_version","unknown")))
		if saved_config.is_empty(): return {"ok":false,"status":"version","error":"未対応の設定版です。元データは保持しました。"}
	var problem := Expedition.validate(parser.data,data,saved_config)
	if problem!="": return {"ok":false,"status":"version" if problem.begins_with("Unsupported") else "invalid","error":problem}
	var migrated:=Expedition.migrate(parser.data)
	problem=Expedition.validate(migrated,data,saved_config)
	if problem!="": return {"ok":false,"status":"invalid","error":problem}
	return {"ok":true,"status":"ok","state":migrated,"config":saved_config,"migrated":parser.data.schema_version==1,"error":""}

func load_game() -> Dictionary:
	fingerprint=digest()
	var current := read_one(path)
	if current.ok:
		cfg=current.config; migration_pending=current.migrated; migration_source=path; return current
	if current.status=="version": return current
	var backup := read_one(path+".bak")
	if backup.ok:
		cfg=backup.config; migration_pending=backup.migrated; migration_source=path+".bak"
		return {"ok":false,"status":"recoverable","state":backup.state,"error":"現在の保存が読めません。前回の保存から復旧できます。元データは退避します。"}
	return current

func preserve_current() -> String:
	return preserve_file(path)

func preserve_file(source: String) -> String:
	if not FileAccess.file_exists(source): return ""
	var archive := source+".preserved-"+str(Time.get_unix_time_from_system()).replace(".","-")
	if FileAccess.file_exists(archive): return "退避先が重複しました。再操作してください。"
	if DirAccess.copy_absolute(source,archive)!=OK: return "元の保存データを退避できません。変更を中止しました。"
	last_preserved_path=archive
	return ""

func write_game(state: Dictionary) -> String:
	var problem := Expedition.validate(state,data,cfg)
	if problem!="": return problem
	if digest()!=fingerprint: return "別の実行が保存を更新しました。タイトルで読み直してください。"
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return "保存先フォルダを作れません。"
	var temporary := path+".tmp"
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file==null: return "一時保存ファイルを作れません。"
	file.store_string(JSON.stringify(state,"\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error!=OK or not read_one(temporary).ok: return "一時保存の検証に失敗しました。"
	if fault=="after_temp": return "Injected failure after temporary write"
	if migration_pending:
		var preservation_error:=preserve_file(migration_source)
		if preservation_error!="": return preservation_error
	if read_one(path).ok:
		if DirAccess.copy_absolute(path,path+".bak")!=OK or not read_one(path+".bak").ok: return "前回保存を保全できません。"
	if fault=="before_replace": return "Injected failure before atomic replacement"
	# Windows MoveFileEx replacement through Godot; never delete main before rename.
	if DirAccess.rename_absolute(temporary,path)!=OK: return "保存の置換に失敗しました。元の保存は保持しています。"
	fingerprint=digest()
	migration_pending=false
	return ""
