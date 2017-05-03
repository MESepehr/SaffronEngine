package otherPlatforms.postMan
{
	import com.mteamapp.JSONParser;
	
	import contents.TextFile;
	
	import flash.filesystem.File;
	
	import otherPlatforms.postMan.model.BodyModel;
	import otherPlatforms.postMan.model.PostManExportModel;

	public class PostManToASFiles
	{
		private static const classFileModel:String = 'package\n{\n\tpublic class [ClassName]\n\t{\n[variables]\n\t\t\n\t\tpublic function [ClassName]()\n\t\t{\n\t\t}\n\t}\n}'
		
		public static function saveClasses(saveToFolderForServices:File, service:String,saveToFolderForTypes:File):void
		{
			// TODO Auto Generated method stub
			var serviceData:PostManExportModel = new PostManExportModel();
			JSONParser.parse(service,serviceData);
			trace("serviceData : "+serviceData.item.length);
			var serviceGenerator:ServiceGenerator = new ServiceGenerator();
			for(var i:uint = 0 ; i<serviceData.item.length ; i++)
			{
				serviceGenerator.ServiceName = correctNames(serviceData.item[i].name) ;
				serviceGenerator.IsGet = serviceData.item[i].request.method=="GET" ;
				serviceGenerator.myWebServiceLocation = serviceData.item[i].request.url ;
				
				serviceGenerator.inputObject = bodyToObject(serviceData.item[i].request.body);
				serviceGenerator.inputObjectClassName = createClassName(serviceGenerator.ServiceName,'Request');
				
				if(serviceData.item[i].response.length>0 && serviceData.item[i].response[0].body!=null)
				{
					trace("***** : "+serviceData.item[i].response[serviceData.item[i].response.length-1].body);
					trace("******** : "+JSONCorrector(serviceData.item[i].response[serviceData.item[i].response.length-1].body));
					serviceGenerator.outPutObject = JSON.parse(JSONCorrector(serviceData.item[i].response[serviceData.item[i].response.length-1].body)) ;
					serviceGenerator.outPutObjectClassName = createClassName(serviceGenerator.ServiceName,'Respond');
					if(serviceGenerator.outPutObject is Array)
					{
						SaveJSONtoAs(serviceGenerator.outPutObject[0],saveToFolderForTypes,serviceGenerator.outPutObjectClassName);
					}
					else
					{
						SaveJSONtoAs(serviceGenerator.outPutObject,saveToFolderForTypes,serviceGenerator.outPutObjectClassName);
					}
				}
				else
				{
					serviceGenerator.outPutObject = null ;
					serviceGenerator.outPutObjectClassName = '' ;
				}
				
				//serviceGenerator.inPutClass = 
				if(serviceGenerator.inputObject!=null)
				{
					SaveJSONtoAs(serviceGenerator.inputObject,saveToFolderForTypes,serviceGenerator.inputObjectClassName);
				}
				
				var serviceFile:File = saveToFolderForServices.resolvePath(serviceGenerator.ServiceName+'.as');
				TextFile.save(serviceFile,serviceGenerator.toString());
			}
		}
		
		/**The wrong names can be like this : http://185.83.208.175:821/api/Service/GetBranches*/
		private static function correctNames(name:String):String
		{
			return name.replace(/^.*\/([^\/]+)/gi,'$1');
		}
		
		private static function bodyToObject(body:BodyModel):Object
		{
			var bodyObject:Object ;
			if(body.mode == "formdata")
			{
				if(body.formdata.length>0)
				{
					bodyObject = {} ;
					for(var i:int ; i<body.formdata.length ; i++)
					{
						bodyObject[body.formdata[i].key] = body.formdata[i].value ;
					}
				}
			}
			else
			{
				if(body.raw!='')
				{
					bodyObject = JSON.parse(JSONCorrector(body.raw)) ;
				}
			}
			return bodyObject;
		}
		
		/**This will replace dfafd:"dfds" with "dfafd":"dfds"*/
		private static function JSONCorrector(wrongJSON:String):String
		{
			return wrongJSON.replace(/([,\{][\s\n\r]*)([a-z]+[\s]*[\s]*):/gi,'$1"$2":') ;
		}
		
		/**This will save the json to as file<br>
		 * Waring!! each class has to have a variable with a special name*/
		public static function SaveJSONtoAs(jsonObject:Object,directory:File,className:String):void
		{
			var myAsClass:String = classFileModel ;
			myAsClass = myAsClass.split("[ClassName]").join(className) ;
			
			var newClassName:String ;
			var parameters:String = '' ;
			var sortedParams:Array = [];
			for(var names:String in jsonObject)
			{
				sortedParams.push(names);
			}
			sortedParams.sort();
			trace("sortedParams : "+sortedParams);
			for(var i:int=0 ; i <sortedParams.length ; i++)
			{
				var paramName:String = sortedParams[i] ;
				parameters+='\t\t/**"'+paramName+'":"'+jsonObject[paramName]+'"*/\n' ;
				parameters+='\t\tpublic var '+paramName+':' ;
				trace(">>>>>"+paramName);
				if(jsonObject[paramName] is String)
				{
					parameters+='String ;'
				}
				else if(jsonObject[paramName] is Number)
				{
					parameters+='Number ;';
				}
				else if(jsonObject[paramName] is Boolean)
				{
					parameters+='Boolean ;';
				}
				else if(jsonObject[paramName] is Array)
				{
					trace(">>>"+paramName);
					if(jsonObject[paramName].length>0 &&
						!(jsonObject[paramName][0] is Number) &&
						!(jsonObject[paramName][0] is String) &&
						!(jsonObject[paramName][0] is Boolean))
					{
						newClassName = createClassName(paramName,"Model",jsonObject[paramName][0]);
						parameters+='Vector.<'+newClassName+'> = new Vector.<'+newClassName+'>()';
						SaveJSONtoAs(jsonObject[paramName][0],directory,newClassName);
					}
					else
					{
						parameters+='Array = [] ;';
					}
				}
				else if(jsonObject[paramName]==null)
				{
					parameters+='* ;';
				}
				else
				{
					//The parameter is class
					
					newClassName = createClassName(paramName,"Model",jsonObject[paramName]);
					parameters+=newClassName+' = new '+newClassName+'()';
					SaveJSONtoAs(jsonObject[paramName],directory,newClassName);
				}
				parameters+='\n';
			}
			myAsClass = myAsClass.split('[variables]').join(parameters);
			
			var targetFile:File = directory.resolvePath(className+'.as') ;
			TextFile.save(targetFile,myAsClass);
		}
		
		/**Craetes a standard class name*/
		private static function createClassName(objectName:String,OffsetName:String = "Model",paramList:Object=null):String
		{
			/*var paramNames:String = '';
			if(paramList!=null)
			{
				var params:Array = [];
				for(var names:String in paramList)
				{
					params.push(names.charAt(0).toUpperCase());
				}
				params.sort();
				paramNames = params.join('');
			}*/
			return objectName.charAt(0).toUpperCase()+objectName.substr(1)+OffsetName/*+paramNames*/ ;
		}
	}
}