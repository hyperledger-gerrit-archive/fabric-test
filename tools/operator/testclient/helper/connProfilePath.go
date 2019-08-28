package helper

//GetConnProfilePathForOrg --
func GetConnProfilePathForOrg(orgName string, organizations []Organization) string {
	var connProfilePath string
	for i := 0; i < len(organizations); i++ {
		if organizations[i].Name == orgName {
			connProfilePath = organizations[i].ConnProfilePath
		}
	}
	return connProfilePath
}