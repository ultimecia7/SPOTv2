function [ tree, root, nodepath] = CreateTree( img, locations )
%CREATETREE Summary of this function goes here
%   Detailed explanation goes here
n=size(locations,1);
dis=inf*ones(n,n);
I=inf*ones(n*n,1);
Itemp=I;
t=0;
for i=1:n
    for j=i+1:n
        if i~=j
        t=t+1;
        dis(i,j)=sqrt(sum((locations(i,:)-locations(j,:)).^2));
        dis(j,i)=dis(i,j);
        I(t)=dis(i,j);
        end
    end
end

Itemp=sort(I, 1, 'ascend');
tree=zeros(n-1,2);
t=0;

for i=1:length(Itemp)
    [tx,ty]=find(dis==min(Itemp));
    x=tx(1);
    y=ty(1);
    [~,idx]=min(Itemp);
    [x1,~]=find(tree(:,1)==x);
    [x2,~]=find(tree(:,1)==y);
   num1=0;
   if isempty(x1)==0 && isempty(x2)==0
    for j=1:length(x1)
        in=find(tree(x1(j),2)==tree(x2,2));
        if length(in)>0
           num1=num1+1;
           Itemp(idx)=inf;
        end
    end
   end
   
   [y1,~]=find(tree(:,2)==x);
   [y2,~]=find(tree(:,2)==y);
   num2=0;
   if isempty(y1)==0 && isempty(y2)==0
    for j=1:length(y1)
        in=find(tree(y1(j),1)==tree(y2,1));
        if length(in)>0
           num2=num2+1;
           Itemp(idx)=inf;
        end
    end
   end
   
   [x3,~]=find(tree(:,1)==x);
   [x4,~]=find(tree(:,2)==y);
   num3=0;
   if isempty(x3)==0 && isempty(x4)==0
    for j=1:length(x3)
        in=find(tree(x3(j),2)==tree(x4,1));
        if length(in)>0
           num3=num3+1;
           Itemp(idx)=inf;
        end
    end
   end
   [y3,~]=find(tree(:,2)==x);
   [y4,~]=find(tree(:,1)==y);
   num4=0;
   if isempty(y3)==0 && isempty(y4)==0
    for j=1:length(y3)
        in=find(tree(y3(j),1)==tree(y4,2));
        if length(in)>0
           num4=num4+1;
           Itemp(idx)=inf;
        end
    end
   end
     
    if num1==0 && num2==0 && num3==0 && num4==0
        t=t+1;
        tree(t,:)=[x y];
        Itemp(idx)=inf;
    end
end

ftree=tree(1,:);
t=1;
conlict{t}=tree(1,:);
for i=2:size(tree,1)
    [x1,~]=find(tree(i,1)==tree(1:i-1,:));
    [x2,~]=find(tree(i,2)==tree(1:i-1,:));
    if isempty(x1) && isempty(x2)
       t=t+1;
       conlict{t}=tree(i,:);
       ftree=[ftree; tree(i,:)];
    elseif isempty(x1) && isempty(x2)==0
       for j=1:t
           ind=find(conlict{j}==tree(i,2));
           if isempty(ind)==0
              conlict{j}=[conlict{j} tree(i,1)];
           end
       end
       ftree=[ftree; tree(i,:)];
    elseif isempty(x1)==0 && isempty(x2)
        for j=1:t
           ind=find(conlict{j}==tree(i,1));
           if isempty(ind)==0
              conlict{j}=[conlict{j} tree(i,2)];
           end
        end
        ftree=[ftree; tree(i,:)];
    elseif isempty(x1)==0 && isempty(x2)==0
        ind1=[];ind2=[];
        for j=1:t
           ind=find(conlict{j}==tree(i,1));
           if isempty(ind)==0
              ind1=j;
           end
        end
        for j=1:t
           ind=find(conlict{j}==tree(i,2));
           if isempty(ind)==0
              ind2=j;
           end
        end
        if ind1<ind2
           conlict{ind1}=[conlict{ind1} conlict{ind2}];
           conlict{ind2}=[];
           ftree=[ftree; tree(i,:)];
        elseif ind1>ind2
           conlict{ind2}=[conlict{ind1} conlict{ind2}]; 
           conlict{ind1}=[];
           ftree=[ftree; tree(i,:)];
        end
    end
end

locations=round(locations);
tree=[];
tree=ftree;
temptree=tree;
cout=n-1;
root=[];
kid=[];
for j=1:cout
    if cout>2          
       for i=1:n
           [x ~]=find(ftree(:)==i);
           if length(x)==1
               if x>size(ftree,1)
                  temptree(x-size(ftree,1),:)=[0 0];
               else
                  temptree(x,:)=[0 0];
               end
              cout=cout-1;
              if size(ftree,1)==n-1;
                 kid=[kid i];
              end
           end
       end
       [x ~]=find(temptree(:,1)==0);
       temptree(x,:)=[];       
       ftree=temptree;
       if size(ftree,1)==3
           for i=1:n
               [x,~]=find(ftree==i);
               if length(x)==3
                   root=i;
                   cout=cout-1;
                   break
               end
           end
       end
       if size(ftree,1)==1
          [x1, ~]=find(tree(:)==ftree(1,1));
          [x2, ~]=find(tree(:)==ftree(1,2));
          if length(x1)>=length(x2)
             root=ftree(1,1); 
          else
             root=ftree(1,2);
          end
       elseif size(ftree,1)==2
          mat=sort(ftree(:));
          for k=1:length(mat)-1
              id=find(mat(k)==mat(k+1));
              if isempty(id)==0
                 root=mat(k);
              end
          end
       end
       if isempty(root)==0
          break
       end
    elseif size(tree,1)==2
       mat=sort(ftree(:));
       for k=1:length(mat)-1
           id=find(mat(k)==mat(k+1));
           if isempty(id)==0
              root=mat(k);
           end
       end 
    elseif size(tree,1)==1
       root=tree(1); 
    end
    for i=1:n
        [ind,y]=find(tree==i);
        if length(ind)==n-1
            root=tree(ind(1),y(1));
        end
    end
end
temptree=tree;
tempnext=[];

if size(temptree,1)==1
   if root==tree(1)
      nodepath{1}=[tree(2) root];
   else
      nodepath{1}=[tree(1) root];
   end
else
for j=1:size(temptree,1)
  if isempty(temptree)
      break
  end
  temp0=[];
  tempkid=[];
  for k=1:n
    [x y]=find(temptree==k);
    if length(x)==1
       tempkid=[tempkid temptree(x,y)];
       if y==1
           tempnext=[tempnext temptree(x,2)];
       else
           tempnext=[tempnext temptree(x,1)];
       end
       temp0=[temp0 x];
    end 
  end
  if j==1
      for i=1:length(tempkid) 
          nodepath{i}=[tempkid(i) tempnext(i)];
      end
      temptree(temp0,:)=[];
  else
   for i=1:length(tempkid)     
    [x y]=find(temptree==tempkid(i));
    if tempkid(i)~=root
    tempind=[];
    for k=1:length(nodepath)
        [m ~]=find(nodepath{k}==tempkid(i));
        if isempty(m)==0
            tempind=[tempind k];
        end
    end
    if y==1
        for k=1:length(tempind)
            nodepath{tempind(k)}=[nodepath{tempind(k)} temptree(x,2)];
        end
        temp0=[temp0 x];
    elseif y==2
        for k=1:length(tempind)
            nodepath{tempind(k)}=[nodepath{tempind(k)} temptree(x,1)];
        end
        temp0=[temp0 x];    
    end
    end
   end
   temptree(temp0,:)=[];
  end
end
end