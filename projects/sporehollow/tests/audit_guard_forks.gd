extends "res://tests/audit_balance_failures.gd"
func run():
	var reports=[]
	for entry in CASES:
		var loaded=Save.read("res://artifacts/balance-fixtures/failure-%d-%s.sav"%[entry[0],entry[1]])
		check(loaded.status=="ok","Read preserved failure morning")
		var result=run_day(Save.restore(loaded.record),entry[1],true,"repair_guard")
		reports.append({"seed":entry[0],"policy":entry[1],"report":result.report})
		check(result.world.result in ["win","loss"],"Guard fork terminates")
		print("GUARD_FORK ",entry," result=",result.world.result," remaining=",result.world.story.idol.hp)
	FileAccess.open("user://guard-forks.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"  "))
	print("GUARD_FORKS: %d checks, failures=%d"%[checks,failures]);quit(1 if failures else 0)
