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
`zgem bundle 'https://github.com/qoomon/zsh-jumper.git' from:'git' use:'zsh-jumper.zsh' as: plugin`

#### parameters
* from
  * git
  * http
  * file (default)
  
* as
  * completion
  * plugin (default)

