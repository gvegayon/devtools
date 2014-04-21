mata
/**
 * @brief Install a module from a git repo
 * @param pkgname Name of the package (repo)
 * @param usr Name of the repo owner
 * @param which Whether to install it from github, bitbucket or googlecode
 */
void function dt_git_install(
	string scalar pkgname,
	| string scalar usr,
	string scalar which,
	string scalar usrpass
	) {

	string colvector valid_repos, out
	string scalar uri
	real scalar shellreturn
	valid_repos = ("github","bitbucket","googlecode")
	
	/* Checking which version */
	if (which == J(1,1,"")) which = "github"
	else if (!length(select(valid_repos,valid_repos:==which)))
		_error(1,"Invalid repo, try using -github-, -bitbucket- or -googlecode-")

	if ((args() < 2) & (which != "googlecode"))
		_error(1, sprintf("%s requieres a -usr- name.", which))

	/* Checking git */
	out = dt_shell("git --version")
	if (!length(out)) 
		_error(1, "It seems that Git is not install in your OS.")
	else if (!regexm(out[1,1],"^git version"))
		_error(1, "It seems that  Git is not install in your OS.")
			
	/* Building the URI */
	if (args() < 4)
	{
		if      (which == "github"   ) uri = sprintf("https://github.com/%s/%s.git", usr, pkgname)
		else if (which == "bitbucket") uri = sprintf("https://bitbucket.org/%s/%s.git", usr, pkgname)
		else if (which == "googlecode") uri = sprintf("https://code.google.com/p/%s/", pkgname)
	}
	else
	{
		if      (which == "github"   ) uri = sprintf("https://%s@github.com/%s/%s.git", usrpass, usr, pkgname)
		else if (which == "bitbucket") uri = sprintf("https://%s@bitbucket.org/%s/%s.git", usrpass, usr, pkgname)
		else if (which == "googlecode") uri = sprintf("https://%s@code.google.com/p/%s/", usrpass, pkgname)
	}
	/* Removing the tmp dir */
	shellreturn=dt_erase_dir(c("tmpdir")+"/"+pkgname)
	
	/* Clonning into git repo */
	out = dt_shell("git clone "+uri+" "+c("tmpdir")+"/"+pkgname)
	if (length(out)) 
		if (regexm(out[1,1],"^(e|E)rror"))
			_error(1,"Could connect to git repo")

	dt_install_on_the_fly(pkgname,J(1,1,""),c("tmpdir")+"/"+pkgname)

	shellreturn=dt_erase_dir(c("tmpdir")+"/"+pkgname)
	
	return
	
}
 
end
