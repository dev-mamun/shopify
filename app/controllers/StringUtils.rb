 #@(#) StringUtils.rb

 # @author Mamun mamun@brainverb.com, Arif arif@brainverb.com
 ##

class StringUtils
       
      require "cgi"  
      attr_accessor :container
       
       #Initialiging object
       def initialize
          @container=""
       end
      #End Initializing
      
      # This method is capable to pares a substring between given range.
      # startIndex= satart position
      # endIndex = destination position
      # If only startIndex is passed as an argument then this function 
      # pares substring from startIndex to end of the string.
      # Retrun value = If every thing is ok it retrun the substring if any exception occour 
      # it return nil   
      def substring(startIndex,endIndex=-1)
        begin
            if(endIndex==-1)
                substr= @container[startIndex..@container.length]  
            elsif(endIndex!=0)
                substr=@container[startIndex..(endIndex-1)]
            else
                substr=""
            end
        rescue
              substr=nil
       end
        return substr    
      end
        
      # This method is capable to find the position of a substring into a string.
      #  Retrun value = If find the substring then retrun the first occurence position of the substring 
      #  otherwile retrun nil as like ruby's own String.index() function.
      def indexof(string)
          return @container.index(string)  
      end    
      
      #This method returns the length of a string.
      def strlen
          return @container.length
      end 
        
      
      # This method is capable to repleace all given old substring by the given new substring of a string  and retrun the regenerated string.
      def replaceAll(oldStr,newStr)
        while @container.index(oldStr)!=nil
              repStr = String.new(oldStr)
              if(@container.index(oldStr)==0)
                str1=""
              else
                str1=@container[0..@container.index(oldStr)-1]
              end
              
              str2=@container[@container.index(oldStr)+oldStr.length..@container.length]
               
              if(newStr!="")
                repStr.replace(newStr)
                @container=str1+repStr+str2
              else
                @container=str1+str2
              end
          end
          return @container  
      end 
      
      # this method is capable to parse all value between a given strat substring to a given end substrin.
      # if isInclude is false then it retruns the value excluding the given start substring & the given end substring.
      # if isInclude is true then it retruns the value including the given start substring & the given end substring.   
      def parseAllValueBetween(startStr,endStr,isInclude=false)
           begin
              if(startStr!=endStr)
              
                  if(!isInclude)
                      val=@container[@container.index(startStr)+startStr.length..@container.index(endStr)-1]
                  else
                      val=@container[@container.index(startStr)..@container.index(endStr)+endStr.length-1]
                  end
                  
              else
                   if(!isInclude)
                      val=@container[@container.index(startStr)+startStr.length..@container.rindex(endStr)-1]
                  else
                      val=@container[@container.index(startStr)..@container.rindex(endStr)+endStr.length-1]
                  end
              end
          rescue
              return nil
          end  
          return val
      end      
      
      #The container method
      def container
         return @container
      end
      
      def get_hidden_fields()
        pattern= /<input.*hidden.*?>/
        
        #@container=str
        #a=str.split(pattern)
        name=""
        value=""
        pstr=""
        n='name="'
        v='value="'
        while(true)
          matches=@container.match(pattern)
          temp_str= matches.to_s
          if(matches==nil)
            break;
          end
          if(temp_str.index(n)==nil)
            n="name='"
          else  
            n='name="'
          end
          if(temp_str.index(v)==nil)
            v="value='"
          else  
            v='value="'
          end
          name = temp_str[temp_str.index(n)+n.length..temp_str.length]
          name=name[0..(name.index('"')-1)]
          value = temp_str[temp_str.index(v)+v.length..temp_str.length]
          value=value[0..(value.index('"')-1)]
          if(value=='">')
            value=""
          end
          if(pstr=="")
            pstr="#{name}=#{CGI.escape(value)}"
          else
            pstr+="&#{name}=#{CGI.escape(value)}"
          end
          @container= @container[@container.index(matches.to_s)+matches.to_s.length..@container.length]
        end
        return pstr
      end
    end


