{
  config,
  lib,
  user,
  ...
}:
{
  # Subset of https://github.com/ohmyzsh/ohmyzsh/blob/887a864aba396c0e6dcf7c0254f455676f830daa/plugins/git/git.plugin.zsh
  hm.programs.fish = lib.mkIf config.home-manager.users.${user}.programs.git.enable {
    functions = {
      "__git.current_branch" = {
        body = /* fish */ ''
          begin
              git symbolic-ref HEAD; or \
              git rev-parse --short HEAD; or return
            end 2>/dev/null | sed -e 's|^refs/heads/||'
        '';
        description = "output git current branch name";
      };
      "__git.main_branch" = {
        body = /* fish */ ''
          command git rev-parse --git-dir &>/dev/null || return

          for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,stable,master}
            if command git show-ref -q --verify $ref
              echo (path basename $ref)
              return 0
            end
          end

          # Fallback: try to get the default branch from remote HEAD symbolic refs
          for remote in origin upstream
            set ref (command git rev-parse --abbrev-ref $remote/HEAD 2>/dev/null)
            if string match -q "$remote/*" $ref
              echo (string replace "$remote/" "" $ref)
              return 0
            end
          end

          # If no main branch was found, fall back to master but return error
          echo master
          return 1
        '';
        description = "output git main branch name";
      };
      "__git.develop_branch" = {
        body = /* fish */ ''
          command git rev-parse --git-dir &>/dev/null || return

          for branch in dev devel develop development
            if command git show-ref -q --verify refs/heads/$branch
              echo $branch
              return 0
            end
          end

          echo develop
          return 1
        '';
        description = "output git develop branch name";
      };

      gbda = {
        body = /* fish */ ''
          git branch --no-color --merged | command grep -vE "^([+*]|\s*($(__git.main_branch)|$(__git.develop_branch))\s*$)" | command xargs git branch --delete 2>/dev/null
        '';
        description = "delete merged git branches";
      };
      gdnolock = {
        body = /* fish */ ''
          git diff $argv ":(exclude)package-lock.json" ":(exclude)*.lock"
        '';
        description = "git diff excluding lockfiles";
        wraps = "git diff";
      };
    };
    shellAbbrs = {
      grt = "cd (git rev-parse --show-toplevel; or echo .)";
      g = "git";
      ga = "git add";
      gaa = "git add --all";
      gapa = "git add --patch";
      gau = "git add --update";
      gav = "git add --verbose";
      gam = "git am";
      gama = "git am --abort";
      gamc = "git am --continue";
      gamscp = "git am --show-current-patch";
      gams = "git am --skip";
      gap = "git apply";
      gapt = "git apply --3way";
      gbs = "git bisect";
      gbsb = "git bisect bad";
      gbsg = "git bisect good";
      gbsn = "git bisect new";
      gbso = "git bisect old";
      gbsr = "git bisect reset";
      gbss = "git bisect start";
      gbl = "git blame -w";
      gb = "git branch";
      gba = "git branch --all";
      gbd = "git branch --delete";
      gbD = "git branch --delete --force";
      # gbda is a function
      gbgd = "LANG=C git branch --no-color -vv | grep ': gone]' | cut -c 3- | awk '{print $1}' | xargs git branch -d";
      gbgD = "LANG=C git branch --no-color -vv | grep ': gone]' | cut -c 3- | awk '{print $1}' | xargs git branch -D";
      gbm = "git branch --move";
      gbnm = "git branch --no-merged";
      gbr = "git branch --remote";
      ggsup = "git branch --set-upstream-to=origin/$(__git.current_branch)";
      gbg = "LANG=C git branch -vv | grep ': gone]'";
      gco = "git checkout";
      gcor = "git checkout --recurse-submodules";
      gcb = "git checkout -b";
      gcB = "git checkout -B";
      gcd = "git checkout $(__git.develop_branch)";
      gcm = "git checkout $(__git.main_branch)";
      gcp = "git cherry-pick";
      gcpa = "git cherry-pick --abort";
      gcpc = "git cherry-pick --continue";
      gclean = "git clean --interactive -d";
      gcl = "git clone --recurse-submodules";
      gclf = "git clone --recursive --shallow-submodules --filter=blob:none --also-filter-submodules";
      gcam = "git commit --all --message";
      gcas = "git commit --all --signoff";
      gcasm = "git commit --all --signoff --message";
      gcs = "git commit --gpg-sign";
      gcss = "git commit --gpg-sign --signoff";
      gcssm = "git commit --gpg-sign --signoff --message";
      gcmsg = "git commit --message";
      gcsm = "git commit --signoff --message";
      gc = "git commit --verbose";
      gca = "git commit --verbose --all";
      "gca!" = "git commit --verbose --all --amend";
      "gcan!" = "git commit --verbose --all --no-edit --amend";
      "gcans!" = "git commit --verbose --all --signoff --no-edit --amend";
      "gcann!" = "git commit --verbose --all --date=now --no-edit --amend";
      "gc!" = "git commit --verbose --amend";
      gcn = "git commit --verbose --no-edit";
      "gcn!" = "git commit --verbose --no-edit --amend";
      gcf = "git config --list";
      gcfu = "git commit --fixup";
      gdct = "git describe --tags $(git rev-list --tags --max-count=1)";
      gd = "git diff";
      gdca = "git diff --cached";
      gdcw = "git diff --cached --word-diff";
      gds = "git diff --staged";
      gdw = "git diff --word-diff";
      gdup = "git diff @{upstream}";
      # gdnolock is a function
      gdt = "git diff-tree --no-commit-id --name-only -r";
      gf = "git fetch";
      gfa = "git fetch --all --tags --prune --jobs=10";
      gfo = "git fetch origin";
      ghh = "git help";
      glgg = "git log --graph";
      glgga = "git log --graph --decorate --all";
      glgm = "git log --graph --max-count=10";
      glods = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset' --date=short";
      glod = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset'";
      glola = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --all";
      glols = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --stat";
      glol = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'";
      glo = "git log --oneline --decorate";
      glog = "git log --oneline --decorate --graph";
      gloga = "git log --oneline --decorate --graph --all";

      glg = "git log --stat";
      glgp = "git log --stat --patch";
      gignored = "git ls-files -v | grep '^[[:lower:]]'";
      gfg = "git ls-files | grep";
      gm = "git merge";
      gma = "git merge --abort";
      gmc = "git merge --continue";
      gms = "git merge --squash";
      gmff = "git merge --ff-only";
      gmom = "git merge origin/$(__git.main_branch)";
      gmum = "git merge upstream/$(__git.main_branch)";
      gmtl = "git mergetool --no-prompt";
      gmtlvim = "git mergetool --no-prompt --tool=vimdiff";

      gl = "git pull";
      gpr = "git pull --rebase";
      gprv = "git pull --rebase -v";
      gpra = "git pull --rebase --autostash";
      gprav = "git pull --rebase --autostash -v";
      gprom = "git pull --rebase origin $(__git.main_branch)";
      gpromi = "git pull --rebase=interactive origin $(__git.main_branch)";
      gprum = "git pull --rebase upstream $(__git.main_branch)";
      gprumi = "git pull --rebase=interactive upstream $(__git.main_branch)";
      ggpull = "git pull origin $(__git.current_branch)";
      gluc = "git pull upstream $(__git.current_branch)";
      glum = "git pull upstream $(__git.main_branch)";
      gp = "git push";
      gpd = "git push --dry-run";
      "gpf!" = "git push --force";
      gpf = "git push --force-with-lease --force-if-includes";
      gpsup = "git push --set-upstream origin $(__git.current_branch)";
      gpsupf = "git push --set-upstream origin $(__git.current_branch) --force-with-lease --force-if-includes";
      gpv = "git push --verbose";
      gpoat = "git push origin --all && git push origin --tags";
      gpod = "git push origin --delete";
      ggpush = "git push origin $(__git.current_branch)";
      gpu = "git push upstream";
      grb = "git rebase";
      grba = "git rebase --abort";
      grbc = "git rebase --continue";
      grbi = "git rebase --interactive";
      grbo = "git rebase --onto";
      grbs = "git rebase --skip";
      grbd = "git rebase $(__git.develop_branch)";
      grbm = "git rebase $(__git.main_branch)";
      grbom = "git rebase origin/$(__git.main_branch)";
      grbum = "git rebase upstream/$(__git.main_branch)";
      grf = "git reflog";
      gr = "git remote";
      grv = "git remote --verbose";
      gra = "git remote add";
      grrm = "git remote remove";
      grmv = "git remote rename";
      grset = "git remote set-url";
      grup = "git remote update";
      grh = "git reset";
      gru = "git reset --";
      grhh = "git reset --hard";
      grhk = "git reset --keep";
      grhs = "git reset --soft";
      gpristine = "git reset --hard && git clean --force -dfx";
      gwipe = "git reset --hard && git clean --force -df";
      groh = "git reset origin/$(__git.current_branch) --hard";
      grs = "git restore";
      grss = "git restore --source";
      grst = "git restore --staged";
      grev = "git revert";
      greva = "git revert --abort";
      grevc = "git revert --continue";
      grm = "git rm";
      grmc = "git rm --cached";
      gcount = "git shortlog --summary --numbered";
      gsh = "git show";
      gsps = "git show --pretty=short --show-signature";
      gstall = "git stash --all";
      gstaa = "git stash apply";
      gstc = "git stash clear";
      gstd = "git stash drop";
      gstl = "git stash list";
      gstp = "git stash pop";
      gsta = "git stash push";
      gsts = "git stash show --patch";
      gst = "git status";
      gss = "git status --short";
      gsb = "git status --short --branch";
      gsi = "git submodule init";
      gsu = "git submodule update";
      gsw = "git switch";
      gswc = "git switch --create";
      gswd = "git switch $(__git.develop_branch)";
      gswm = "git switch $(__git.main_branch)";
      gta = "git tag --annotate";
      gts = "git tag --sign";
      gtv = "git tag | sort -V";
      gignore = "git update-index --assume-unchanged";
      gunignore = "git update-index --no-assume-unchanged";
      gwch = "git log --patch --abbrev-commit --pretty=medium --raw";
      gwt = "git worktree";
      gwta = "git worktree add";
      gwtls = "git worktree list";
      gwtmv = "git worktree move";
      gwtrm = "git worktree remove";
      gstu = "gsta --include-untracked";
    };
  };
}
