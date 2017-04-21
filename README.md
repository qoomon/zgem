# zgem
zsh dependency manager

### install
  
```
#### load zgem 
ZGEM_HOME="$HOME/.zgem"
ZGEM_UTILS_DIR="$ZCONFIG_HOME/utils"
test ! -e "$ZGEM_HOME" && git clone 'https://github.com/qoomon/zgem.git' "$ZGEM_HOME"
source "$ZGEM_HOME/zgem.zsh" # && ZGEM_VERBOSE='true'
```
  
### usage
* load plugin form git source 
  * `zgem bundle 'https://github.com/qoomon/zsh-jumper.git' from:'git' use:'zsh-jumper.zsh'`
* load plugin from local source
  * `zgem bundle "$HOME/.zsh/awesome.zsh"`
* load completion from http source
  * `zgem bundle "http://example.org/completions/_awesome" from:http as:completion`
* load plugin on demand from $ZGEM_UTILS_DIR directory
  * `zgem awesome`

#### parameters
* from
  * git
  * http
  * file (default)
  
* use
  * custom file name to load
  * basename from source url (default)
  
* as
  * completion
  * plugin (default)
