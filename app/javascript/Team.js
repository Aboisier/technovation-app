export default function Team (res) {
  this.id = res.id || "";
  this.name = res.name || "";
  this.scope = res.scope;
  this.status = res.status || "status missing (bug)";
  this.human_status = res.human_status || "must sign up";

  this.location = res.location;

  this.highlighted = false;
  this.sendInvitation = false;
  this.recentlyAdded = false;
  this.recentlyInvited = false;

  this.prepareToBeInvited = (event) => {
    this.recentlyAdded = true;
    this.sendInvitation = true;
  };

  this.highlight = () => {
    this.highlighted = true;
  };

  this.unhighlight = () => {
    this.highlighted = false;
  };

  this.match = (namePattern) => {
    var name_spec = new RegExp(namePattern, "i");

    return !!this.name.match(name_spec);
  };

  this.highlightMatch = (prop, query) => {
    var regexp = new RegExp("(" + query + ")", "gi");
    return this[prop].replace(regexp, "<b>$1</b>");
  };

  this.afterAssign = () => {
    if (this.sendInvitation) {
      this.recentlyInvited = true;
      this.sendInvitation = false;
    }

    if (this.recentlyAdded)
      this.recentlyAdded = false;
  };
};