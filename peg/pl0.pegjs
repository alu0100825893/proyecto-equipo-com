/*
 * Classic example grammar, which recognizes simple arithmetic expressions like
 * "2*(3+4)". The parser generated from this grammar then AST.
 */
//pegjs pl0.pegjs ../models/pl0.js
{
  var tree = function(f, r) {
    if (r.length > 0) {
      var last = r.pop();
      var result = {
        type:  last[0],
        left: tree(f, r),
        right: last[1]
      };
    }
    else {
      var result = f;
    }
    return result;
  }
}

program = b:block{ b.name = {type: 'ID', value: "$main"}; b.params = []; return b;}

block = cD:constantDeclarations? vD:varDeclarations? fD:functionDeclaration* st:st {
          cD = cD? cD : [];
          vD = vD? vD : [];

          var sT = {
            father: null
          };

          cD.forEach(function(x) {
            sT[x[0]] = x;
          });

          vD.forEach(function(x) {
            sT[x] = x;
          });

          fD.forEach(function(x) {
            //console.log(x);
            sT[x.name] = x;
          });

          return {
              type: 'BLOCK',
              constants: cD,
              variables: vD,
              functions: fD,
              symbolTable: sT,
              main: st
          };
        }

constantDeclarations = CONST id:ID ASSIGN n:NUMBER rest:(COMMA ID ASSIGN NUMBER)* SC
                        {
                          var result = rest.map( function(x) { return [x[1].value, x[3].value] });

                          return [[id.value,n.value]].concat(result);
                        }

varDeclarations = VAR id:ID rest:(COMMA ID)* SC
                    {
                      var result = rest.map( function(x) { return x[1].value; });

                      return [id.value].concat(result);
                    }

functionDeclaration = FUNCTION id:ID LEFTPAR !COMMA p:ID? rp:(COMMA ID)* RIGHTPAR b:block SC
                      {
                        var result = [];
                        if (p) result.push(p.value);

                        result = result.concat(rp.map(function(x) { return x[1].value; }));

                      return Object.assign(b,{
                         type: 'FUNCTION',
                         name: id.value,
                         params: result
                       });
                      }

st = CL first:st? rest:(SC st)* CR {
            var result = [];

            if (first) result.push(first);

            if(rest.length != 0) {
                var aux = rest.map(function(x) {
                    return x[1];
                });

                result = result.concat(aux);
            }
            return {
              type: 'COMPOUND',
              children: result
            }
        }

     / IF e:exp THEN st:st ELSE sf:st
           {
             return {
               type: 'IFELSE',
               c:  e,
               st: st,
               sf: sf,
             };
           }
       / IF e:exp THEN st:st
           {
             return {
               type: 'IF',
               c:  e,
               st: st
             };
           }
        / WHILE c:exp DO st:st {
            return {
              type: 'WHILE',
              c:  c,
              st: st
            };
        }
        / RETURN e:exp {
            return {
              type: 'RETURN',
              children: e
            };
        }
        / assign

assign = i:ID ASSIGN e:exp
            { return {type: '=', left: i, right: e}; }
exp    = left:term comp:COMP right:term {
          return {
            type: comp,
            left: left,
            right: right
          };
        }
        / t:term   r:(ADD term)*   { return tree(t,r); }
term   = f:factor r:(MUL factor)* { return tree(f,r); }

factor = assign
        / f:ID LEFTPAR e:exp? r:(COMMA exp)* RIGHTPAR {
            var result = [];

            if (e) result.push(e);

            if(r.length != 0) {
                var aux = r.map(function(x) {
                    return x[1];
                });

                result = result.concat(aux);
            }

            return {
              type: 'CALL',
              func: f,
              arguments: result
            }
        }
        / NUMBER
        / ID
        / LEFTPAR t:exp RIGHTPAR   { return t; }


_ = $[ \t\n\r]*

ASSIGN   = _ op:'=' _  { return op; }
ADD      = _ op:[+-] _ { return op; }
MUL      = _ op:[*/] _ { return op; }
LEFTPAR  = _"("_
RIGHTPAR = _")"_
CL       = _ "{" _
CR       = _ "}" _
SC = _ ";" _
COMMA = _ "," _
IF       = _ "if" _
THEN     = _ "then" _
ELSE     = _ "else" _
WHILE    = _ "while" _
DO       = _ "do" _
RETURN   = _ "return" _
CONST    = _ "const" _
VAR      = _ "var" _
FUNCTION = _ "function" _
ID       = _ id:$([a-zA-Z_][a-zA-Z_0-9]*) _
            {
              return { type: 'ID', value: id };
            }
NUMBER   = _ digits:$[0-9]+ _
            {
              return { type: 'NUM', value: parseInt(digits, 10) };
            }
COMP = _ comp:("=="/"!="/"<="/">="/"<"/">") _ { return comp; }
